//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
///
/// HTTPResponseEncoderTest+XCTest.swift
///
import XCTest

///
/// NOTE: This file was generated by generate_linux_tests.rb
///
/// Do NOT edit this file directly as it will be regenerated automatically when needed.
///

extension HTTPResponseEncoderTests {

   static var allTests : [(String, (HTTPResponseEncoderTests) -> () throws -> Void)] {
      return [
                ("testNoAutoHeadersFor101", testNoAutoHeadersFor101),
                ("testNoAutoHeadersForCustom1XX", testNoAutoHeadersForCustom1XX),
                ("testNoAutoHeadersFor204", testNoAutoHeadersFor204),
                ("testNoContentLengthHeadersFor101", testNoContentLengthHeadersFor101),
                ("testNoContentLengthHeadersForCustom1XX", testNoContentLengthHeadersForCustom1XX),
                ("testNoContentLengthHeadersFor204", testNoContentLengthHeadersFor204),
                ("testNoTransferEncodingHeadersFor101", testNoTransferEncodingHeadersFor101),
                ("testNoTransferEncodingHeadersForCustom1XX", testNoTransferEncodingHeadersForCustom1XX),
                ("testNoTransferEncodingHeadersFor204", testNoTransferEncodingHeadersFor204),
                ("testNoChunkedEncodingForHTTP10", testNoChunkedEncodingForHTTP10),
           ]
   }
}
