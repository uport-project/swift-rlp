private let ELEMENT_OFFSET = 128
private let LIST_OFFSET = 192

enum RLPError: Error {
    /// represents if the receiver can’t be converted without losing some
    /// information (such as accents or case) for attempted String conversion
    case toRLPConversionLosesInformation
    case encodingCallerTypeBad( description: String )
    case dataMissingFirstByte
    /// data has all bytes that are zero or no bytes at all
    case dataHasAllZeroBytes
}


extension RLPType {
    public func encodeRLP() throws -> Data? {
        if let element = self as? RLPElement {
            return try! element.bytes.encoded( offset: ELEMENT_OFFSET )
        } else if self is RLPList {
            return nil
        }

        throw RLPError.encodingCallerTypeBad( description: "RLPType must be RLPElement or RLPList" )
    }

}

extension Data {
    fileprivate func encoded( offset: Int ) throws -> Data {
        let firstByte: UInt8 = self.first ?? 0
        if self.count == 1 && ( firstByte & 0xff < 128 ) && offset == ELEMENT_OFFSET {
            return self
        } else if self.count <= 55 {
            let byte = UInt8( self.count + offset )
            var someData = Data( bytes: [byte] )
            someData.append(self)
            return someData
        }

        let minimalData = self.count.toMinimalData()
        let byte = UInt8( offset + 0x37 + minimalData.count )
        var someData = Data( bytes: [byte] )
        someData.append(minimalData)
        someData.append(self)
        return someData
    }

    fileprivate func minimalStart() throws -> Int {
        guard let indexOfNonZeroByte = self.index( where: { $0 != 0 } ) else {
            throw RLPError.dataHasAllZeroBytes
        }

        return indexOfNonZeroByte == -1 ? 4 : indexOfNonZeroByte
    }

    public func removeLeadingZero() throws -> Data {
        guard let firstByteAsInt = self.first else {
            throw RLPError.dataHasAllZeroBytes
        }

        return firstByteAsInt == 0 ? self.suffix(1) : self
    }
}

extension String {
    /// Throws if the receiver can’t be converted without losing some information (such as accents or case)
    public func toRLP() throws -> RLPElement {
        guard let bytes = self.data( using: .utf8 ) else { throw RLPError.toRLPConversionLosesInformation }
        return RLPElement.init( bytes: bytes )
    }
}

extension Int {
    public func toRLP() throws -> RLPElement {
        if self == 0 {
            return RLPElement.init( bytes: Data() )
        }
        
        return RLPElement.init( bytes: self.toMinimalData() )
    }
}

public class RLPElement: NSObject, RLPType {
    public var bytes: Data

    init( bytes: Data ) {
        self.bytes = bytes
        super.init()
    }
}


public class RLPList: NSObject, RLPType {
    public var list: [RLPType]
    
    init( list: [RLPType] ) {
        self.list = list
        super.init()
    }
}

public protocol RLPType {}

extension Int {
    public func toData() -> Data {
        var output = Data()
        for i in 0..<4 {
            let numBitsToShift = 8 * (3 - i)
            let isolatedBits = UInt8( (self >> numBitsToShift) & 0xff )
            output.append( isolatedBits )
        }

        return output
    }

    public func toMinimalData() -> Data {
        let data = self.toData()
        let minimalStart = try! data.minimalStart()
        let count = 4 - minimalStart
        var outputData = [UInt8]( repeating:0, count: count )
        data.copyBytes( to: &outputData, from: minimalStart..<4 )
        return Data( bytes: outputData )
    }
}

//fun Int.toByteArray() = ByteArray(4, { i -> shr(8 * (3 - i)).toByte() })
//fun Int.toMinimalByteArray() = toByteArray().let { it.copyOfRange(it.minimalStart(), 4) }

//private fun ByteArray.minimalStart() = indexOfFirst { it != 0.toByte() }.let { if (it == -1) 4 else it }
//fun ByteArray.removeLeadingZero() = if (first() == 0.toByte()) copyOfRange(1, size) else this
