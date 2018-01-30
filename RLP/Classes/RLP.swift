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
    public func rlpEncodedData() throws -> Data? {
        if let rlpTypeELement = self as? RLPElement {
            return try! rlpTypeELement.bytes.encoded( offset: ELEMENT_OFFSET )
        } else if let rlpTypeList = self as? RLPList {
            let mappedData = try! rlpTypeList.list.map({ (element) throws -> Data?  in
                return try! element.rlpEncodedData()
            })
            
            let reducedMutableData = mappedData.reduce(NSMutableData(), { ( accumulator, bytes) -> NSMutableData in
                accumulator.append( bytes! )
                return accumulator
            })

            let reducedData = reducedMutableData as Data
            return try! reducedData.encoded(offset: LIST_OFFSET)
//            is RLPList -> element.map { it.encode() }
//                .fold(ByteArray(0), { acc, bytes -> acc + bytes }) // this can be speed optimized when needed
//                .encode(LIST_OFFSET)
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
    public func toRLPType() throws -> RLPElement {
        guard let bytes = self.data( using: .utf8 ) else { throw RLPError.toRLPConversionLosesInformation }
        return RLPElement.init( bytes: bytes )
    }
}

extension Int {
    public func toRLPType() throws -> RLPElement {
        if self == 0 {
            return RLPElement.init( bytes: Data() )
        }
        
        return RLPElement.init( bytes: self.toMinimalData() )
    }
}

public class RLPElement: NSObject, RLPType {
    public var bytes: Data

    public init( bytes: Data ) {
        self.bytes = bytes
        super.init()
    }
}


public class RLPList: NSObject, RLPType {
    public var list: [RLPType]
    
    public init( list: [RLPType] ) {
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

