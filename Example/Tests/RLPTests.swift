//
//  TestRLP.swift
//  RLP_Tests
//
//  Created by josh on 1/27/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Quick
import Nimble
import RLP
import NSData_FastHex

extension String {
    
    fileprivate func dataFromHex() -> Data {
        // Based on: http://stackoverflow.com/a/2505561/313633
        var data = NSMutableData()
        
        var temp = ""
        
        for char in self {
            temp+=String(char)
            if(temp.count == 2) {
                let scanner = Scanner(string: temp)
                var value: CUnsignedInt = 0
                scanner.scanHexInt32(&value)
                data.append(&value, length: 1)
                temp = ""
            }
            
        }
        
        return data as NSData as Data
    }
}

class RLPTests: QuickSpec {
    
    func encodedData( string: String ) -> Data? {
        let rlpType = try! string.toRLPType()
        return try! (rlpType as RLPType).rlpEncodedData()
    }

    func encodedData( aInt: Int ) -> Data? {
        let rlpType = try! aInt.toRLPType()
        return try! (rlpType as RLPType).rlpEncodedData()
    }
    
    func data( hexString: String ) -> Data {
//        return NSData( hexString: hexString ) as Data
        return hexString.dataFromHex()
    }


    override func spec() {
        describe("Encoding works") {
            it("can encode strings") {
                let emptyStringBytes = self.encodedData( string: "" )
                let referenceEmptyData = self.data( hexString: "80" )
                expect( emptyStringBytes ) == referenceEmptyData
                
                let dogBytes = self.encodedData( string: "dog" )
                let referenceDogData = self.data( hexString: "83646f67" )
                expect( dogBytes ) == referenceDogData
                
                let latin1Bytes = self.encodedData( string: "Lorem ipsum dolor sit amet, consectetur adipisicing eli" )
                let referenceLatin1Bytes = self.data( hexString: "b74c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c69" )
                expect( latin1Bytes ) == referenceLatin1Bytes
                
//                let latin2Bytes = self.encodedData( string: "Lorem ipsum dolor sit amet, consectetur adipisicing elit" )
                let rlpType = try! "Lorem ipsum dolor sit amet, consectetur adipisicing elit".toRLPType()
                let encodedRLP = try! (rlpType as! RLPType).rlpEncodedData()
                let referenceLatin2Bytes = self.data( hexString: "b8384c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e7365637465747572206164697069736963696e6720656c6974" )
                expect( encodedRLP ) == referenceLatin2Bytes
                
                let longLatinBytes = self.encodedData( string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur mauris magna, suscipit sed vehicula non, iaculis faucibus tortor. Proin suscipit ultricies malesuada. Duis tortor elit, dictum quis tristique eu, ultrices at risus. Morbi a est imperdiet mi ullamcorper aliquet suscipit nec lorem. Aenean quis leo mollis, vulputate elit varius, consequat enim. Nulla ultrices turpis justo, et posuere urna consectetur nec. Proin non convallis metus. Donec tempor ipsum in mauris congue sollicitudin. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Suspendisse convallis sem vel massa faucibus, eget lacinia lacus tempor. Nulla quis ultricies purus. Proin auctor rhoncus nibh condimentum mollis. Aliquam consequat enim at metus luctus, a eleifend purus egestas. Curabitur at nibh metus. Nam bibendum, neque at auctor tristique, lorem libero aliquet arcu, non interdum tellus lectus sit amet eros. Cras rhoncus, metus ac ornare cursus, dolor justo ultrices metus, at ullamcorper volutpat" )
                
                let longLatinReferenceBytes = self.data( hexString: "b904004c6f72656d20697073756d20646f6c6f722073697420616d65742c20636f6e73656374657475722061646970697363696e6720656c69742e20437572616269747572206d6175726973206d61676e612c20737573636970697420736564207665686963756c61206e6f6e2c20696163756c697320666175636962757320746f72746f722e2050726f696e20737573636970697420756c74726963696573206d616c6573756164612e204475697320746f72746f7220656c69742c2064696374756d2071756973207472697374697175652065752c20756c7472696365732061742072697375732e204d6f72626920612065737420696d70657264696574206d6920756c6c616d636f7270657220616c6971756574207375736369706974206e6563206c6f72656d2e2041656e65616e2071756973206c656f206d6f6c6c69732c2076756c70757461746520656c6974207661726975732c20636f6e73657175617420656e696d2e204e756c6c6120756c74726963657320747572706973206a7573746f2c20657420706f73756572652075726e6120636f6e7365637465747572206e65632e2050726f696e206e6f6e20636f6e76616c6c6973206d657475732e20446f6e65632074656d706f7220697073756d20696e206d617572697320636f6e67756520736f6c6c696369747564696e2e20566573746962756c756d20616e746520697073756d207072696d697320696e206661756369627573206f726369206c756374757320657420756c74726963657320706f737565726520637562696c69612043757261653b2053757370656e646973736520636f6e76616c6c69732073656d2076656c206d617373612066617563696275732c2065676574206c6163696e6961206c616375732074656d706f722e204e756c6c61207175697320756c747269636965732070757275732e2050726f696e20617563746f722072686f6e637573206e69626820636f6e64696d656e74756d206d6f6c6c69732e20416c697175616d20636f6e73657175617420656e696d206174206d65747573206c75637475732c206120656c656966656e6420707572757320656765737461732e20437572616269747572206174206e696268206d657475732e204e616d20626962656e64756d2c206e6571756520617420617563746f72207472697374697175652c206c6f72656d206c696265726f20616c697175657420617263752c206e6f6e20696e74657264756d2074656c6c7573206c65637475732073697420616d65742065726f732e20437261732072686f6e6375732c206d65747573206163206f726e617265206375727375732c20646f6c6f72206a7573746f20756c747269636573206d657475732c20617420756c6c616d636f7270657220766f6c7574706174" )
                expect( longLatinBytes ) == longLatinReferenceBytes
            }

            it("can encode Ints") {
                let rlpType = try! 0.toRLPType()
                let stringEmptyType = try! "".toRLPType()
                let encodedZero = try! (rlpType as! RLPType).rlpEncodedData()
                let encodedEmptyString = try! (stringEmptyType as! RLPType).rlpEncodedData()
                expect( encodedZero ) == self.data( hexString:"80" )
                
                let rlpType2 = try! 1.toRLPType()
                let encodedOne = try! (rlpType2 as! RLPType).rlpEncodedData()
                let expectedData = self.data( hexString: "01" )
                expect( encodedOne ) == expectedData
                expect( self.encodedData( aInt: 16) ) == self.data( hexString: "10" )
                expect( self.encodedData( aInt: 79 ) ) == self.data( hexString: "4f" )
                expect( self.encodedData( aInt: 127 ) ) == self.data( hexString: "7f" )
                expect( self.encodedData( aInt: 128 ) ) == self.data( hexString: "8180" )
                
                let rlpTypeThousand = try! 1000.toRLPType()
                let encodedThousand = try! (rlpTypeThousand as! RLPType).rlpEncodedData()
                let expectedThousandData = self.data( hexString: "8203e8" )
                expect( encodedThousand ) == expectedThousandData
                expect( self.encodedData( aInt: 1000 ) ) == self.data( hexString: "8203e8" )
                expect( self.encodedData( aInt: 100000 ) ) == self.data( hexString: "830186a0" )
            }

            it("can encode arrays") {
                expect( try! RLPList( list: [RLPType]()).rlpEncodedData()) == "c0".dataFromHex()
                
                let rlpList: [RLPType] = [ try! "dog".toRLPType(), try! "god".toRLPType(), try! "cat".toRLPType() ]
                expect( try! RLPList( list: rlpList ).rlpEncodedData() ) == "cc83646f6783676f6483636174".dataFromHex()

                let rlpList2: [RLPType] = [ try! "zw".toRLPType(), RLPList( list: [try! 4.toRLPType()]), try! 1.toRLPType() ]
                expect( try! RLPList( list: rlpList2 ).rlpEncodedData() ) == "c6827a77c10401".dataFromHex()

                let rlpList3  = RLPList( list: [RLPList( list: [RLPList(list:[RLPType]()), RLPList(list: [RLPType]())]), RLPList(list:[RLPType]())])
                expect( try! rlpList3.rlpEncodedData() ) == "c4c2c0c0c0".dataFromHex()
            }

        }
 
    }
    
}
