//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// ByteBufferLengthPrefixTests+XCTest.swift
//
import XCTest

///
/// NOTE: This file was generated by generate_linux_tests.rb
///
/// Do NOT edit this file directly as it will be regenerated automatically when needed.
///

extension ByteBufferLengthPrefixTests {

   @available(*, deprecated, message: "not actually deprecated. Just deprecated to allow deprecated tests (which test deprecated functionality) without warnings")
   static var allTests : [(String, (ByteBufferLengthPrefixTests) -> () throws -> Void)] {
      return [
                ("testWriteMessageWithLengthOfZero", testWriteMessageWithLengthOfZero),
                ("testWriteMessageWithLengthOfOne", testWriteMessageWithLengthOfOne),
                ("testWriteMessageWithMultipleWrites", testWriteMessageWithMultipleWrites),
                ("testWriteMessageWithMaxLength", testWriteMessageWithMaxLength),
                ("testWriteTooLongMessage", testWriteTooLongMessage),
                ("testWriteMessageWithBigEndianInteger", testWriteMessageWithBigEndianInteger),
                ("testWriteMessageWithLittleEndianInteger", testWriteMessageWithLittleEndianInteger),
                ("testReadMessageWithLengthOfZero", testReadMessageWithLengthOfZero),
                ("testReadMessageWithLengthOfOne", testReadMessageWithLengthOfOne),
                ("testReadMessageWithLengthOfTen", testReadMessageWithLengthOfTen),
                ("testReadMessageWithMaxLength", testReadMessageWithMaxLength),
                ("testReadOneByteTooMuch", testReadOneByteTooMuch),
                ("testReadOneByteTooFew", testReadOneByteTooFew),
                ("testReadMessageWithBigEndianInteger", testReadMessageWithBigEndianInteger),
                ("testReadMessageWithLittleEndianInteger", testReadMessageWithLittleEndianInteger),
                ("testReadMessageWithMaliciousLength", testReadMessageWithMaliciousLength),
                ("testReadMessageWithNegativeLength", testReadMessageWithNegativeLength),
                ("testReadSliceWithBigEndianInteger", testReadSliceWithBigEndianInteger),
                ("testReadSliceWithLittleEndianInteger", testReadSliceWithLittleEndianInteger),
                ("testGetSliceWithBigEndianInteger", testGetSliceWithBigEndianInteger),
                ("testGetSliceWithLittleEndianInteger", testGetSliceWithLittleEndianInteger),
           ]
   }
}

