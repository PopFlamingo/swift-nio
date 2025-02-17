//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2021 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import NIOCore
@testable import NIOPosix

class SocketAddressTest: XCTestCase {

    func testDescriptionWorks() throws {
        var ipv4SocketAddress = sockaddr_in()
        let res = "10.0.0.1".withCString { p in
            inet_pton(NIOBSDSocket.AddressFamily.inet.rawValue, p, &ipv4SocketAddress.sin_addr)
        }
        XCTAssertEqual(res, 1)
        ipv4SocketAddress.sin_port = (12345 as in_port_t).bigEndian
        let sa = SocketAddress(ipv4SocketAddress, host: "foobar.com")
        XCTAssertEqual("[IPv4]foobar.com/10.0.0.1:12345", sa.description)
    }

    func testDescriptionWorksWithoutIP() throws {
        var ipv4SocketAddress = sockaddr_in()
        ipv4SocketAddress.sin_port = (12345 as in_port_t).bigEndian
        let sa = SocketAddress(ipv4SocketAddress, host: "foobar.com")
        XCTAssertEqual("[IPv4]foobar.com/0.0.0.0:12345", sa.description)
    }
    
    func testDescriptionWorksWithIPOnly() throws {
        let sa = try! SocketAddress(ipAddress: "10.0.0.2", port: 12345)
        XCTAssertEqual("[IPv4]10.0.0.2:12345", sa.description)
    }
    
    func testDescriptionWorksWithByteBufferIPv4IP() throws {
        let IPv4: [UInt8] = [0x7F, 0x00, 0x00, 0x01]
        let ipv4Address: ByteBuffer = ByteBuffer.init(bytes: IPv4)
        let sa = try! SocketAddress(packedIPAddress: ipv4Address, port: 12345)
        XCTAssertEqual("[IPv4]127.0.0.1:12345", sa.description)
    }
    
    func testDescriptionWorksWithByteBufferIPv6IP() throws {
        let IPv6: [UInt8] = [0xfe, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05]
        let ipv6Address: ByteBuffer = ByteBuffer.init(bytes: IPv6)
        let sa = try! SocketAddress(packedIPAddress: ipv6Address, port: 12345)
        XCTAssertEqual("[IPv6]fe80::5:12345", sa.description)
    }
    
    func testRejectsWrongIPByteBufferLength() {
        let wrongIP: [UInt8] = [0x01, 0x7F, 0x00]
        let ipAddress: ByteBuffer = ByteBuffer.init(bytes: wrongIP)
        XCTAssertThrowsError(try SocketAddress(packedIPAddress: ipAddress, port: 12345)) { error in
            switch error {
            case is SocketAddressError.FailedToParseIPByteBuffer:
                XCTAssertEqual(ipAddress, (error as! SocketAddressError.FailedToParseIPByteBuffer).address)
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
    }
    
    func testIn6AddrDescriptionWorks() throws {
        let sampleString = "::1"
        let sampleIn6Addr: [UInt8] = [ // ::1
            0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
            0x0, 0x0, 0x1, 0x0, 0x0, 0x0, 0x0, 0x0, 0x70, 0x0, 0x0, 0x54,
            0xc2, 0xb5, 0x58, 0xff, 0x7f, 0x0, 0x0, 0x7,
            0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x40, 0x1, 0x1, 0x0
        ]

        var address         = sockaddr_in6()
        #if os(Linux) || os(Android) // no sin6_len on Linux/Android
        #else
          address.sin6_len  = UInt8(MemoryLayout<sockaddr_in6>.size)
        #endif
        address.sin6_family = sa_family_t(NIOBSDSocket.AddressFamily.inet6.rawValue)
        address.sin6_addr   = sampleIn6Addr.withUnsafeBytes {
            $0.baseAddress!.bindMemory(to: in6_addr.self, capacity: 1).pointee
        }

        let s = __testOnly_addressDescription(address)
        XCTAssertEqual(s.count, sampleString.count,
                       "Address description has unexpected length 😱")
        XCTAssertEqual(s, sampleString,
                       "Address description is way below our expectations 😱")
    }
	
    func testIPAddressWorks() throws {
        let sa = try! SocketAddress(ipAddress: "127.0.0.1", port: 12345)
        XCTAssertEqual("127.0.0.1", sa.ipAddress)
        let sa6 = try! SocketAddress(ipAddress: "::1", port: 12345)
        XCTAssertEqual("::1", sa6.ipAddress)
        let unix = try! SocketAddress(unixDomainSocketPath: "/definitely/a/path")
        XCTAssertEqual(nil, unix.ipAddress)
    }

    func testCanCreateIPv4AddressFromString() throws {
        let sa = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        let expectedAddress: [UInt8] = [0x7F, 0x00, 0x00, 0x01]
        if case .v4(let address) = sa {
            var addr = address.address
            let host = address.host
            XCTAssertEqual(host, "")
            XCTAssertEqual(addr.sin_family, sa_family_t(NIOBSDSocket.AddressFamily.inet.rawValue))
            XCTAssertEqual(addr.sin_port, in_port_t(80).bigEndian)
            expectedAddress.withUnsafeBytes { expectedPtr in
                withUnsafeBytes(of: &addr.sin_addr) { actualPtr in
                    let rc = memcmp(actualPtr.baseAddress!, expectedPtr.baseAddress!, MemoryLayout<in_addr>.size)
                    XCTAssertEqual(rc, 0)
                }
            }
        } else {
            XCTFail("Invalid address: \(sa)")
        }
    }

    func testCanCreateIPv6AddressFromString() throws {
        let sa = try SocketAddress(ipAddress: "fe80::5", port: 443)
        let expectedAddress: [UInt8] = [0xfe, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05]
        if case .v6(let address) = sa {
            var addr = address.address
            let host = address.host
            XCTAssertEqual(host, "")
            XCTAssertEqual(addr.sin6_family, sa_family_t(NIOBSDSocket.AddressFamily.inet6.rawValue))
            XCTAssertEqual(addr.sin6_port, in_port_t(443).bigEndian)
            XCTAssertEqual(addr.sin6_scope_id, 0)
            XCTAssertEqual(addr.sin6_flowinfo, 0)
            expectedAddress.withUnsafeBytes { expectedPtr in
                withUnsafeBytes(of: &addr.sin6_addr) { actualPtr in
                    let rc = memcmp(actualPtr.baseAddress!, expectedPtr.baseAddress!, MemoryLayout<in6_addr>.size)
                    XCTAssertEqual(rc, 0)
                }
            }
        } else {
            XCTFail("Invalid address: \(sa)")
        }
    }

    func testRejectsNonIPStrings() {
        XCTAssertThrowsError(try SocketAddress(ipAddress: "definitelynotanip", port: 800)) { error in
            switch error as? SocketAddressError {
            case .some(.failedToParseIPString("definitelynotanip")):
                () // ok
            default:
                XCTFail("unexpected error: \(error)")
            }
        }
    }

    func testConvertingStorage() throws {
        let first = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        let second = try SocketAddress(ipAddress: "::1", port: 80)
        let third = try SocketAddress(unixDomainSocketPath: "/definitely/a/path")

        guard case .v4(let firstAddress) = first else {
            XCTFail("Unable to extract IPv4 address")
            return
        }
        guard case .v6(let secondAddress) = second else {
            XCTFail("Unable to extract IPv6 address")
            return
        }
        guard case .unixDomainSocket(let thirdAddress) = third else {
            XCTFail("Unable to extract UDS address")
            return
        }

        var storage = sockaddr_storage()
        var firstIPAddress = firstAddress.address
        var secondIPAddress = secondAddress.address
        var thirdIPAddress = thirdAddress.address

        var firstCopy: sockaddr_in = withUnsafeBytes(of: &firstIPAddress) { outer in
            _ = withUnsafeMutableBytes(of: &storage) { temp in
                memcpy(temp.baseAddress!, outer.baseAddress!, MemoryLayout<sockaddr_in>.size)
            }
            return __testOnly_convertSockAddr(storage)
        }
        var secondCopy: sockaddr_in6 = withUnsafeBytes(of: &secondIPAddress) { outer in
            _ = withUnsafeMutableBytes(of: &storage) { temp in
                memcpy(temp.baseAddress!, outer.baseAddress!, MemoryLayout<sockaddr_in6>.size)
            }
            return __testOnly_convertSockAddr(storage)
        }
        var thirdCopy: sockaddr_un = withUnsafeBytes(of: &thirdIPAddress) { outer in
            _ = withUnsafeMutableBytes(of: &storage) { temp in
                memcpy(temp.baseAddress!, outer.baseAddress!, MemoryLayout<sockaddr_un>.size)
            }
            return __testOnly_convertSockAddr(storage)
        }

        XCTAssertEqual(memcmp(&firstIPAddress, &firstCopy, MemoryLayout<sockaddr_in>.size), 0)
        XCTAssertEqual(memcmp(&secondIPAddress, &secondCopy, MemoryLayout<sockaddr_in6>.size), 0)
        XCTAssertEqual(memcmp(&thirdIPAddress, &thirdCopy, MemoryLayout<sockaddr_un>.size), 0)
    }

    func testComparingSockaddrs() throws {
        let first = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        let second = try SocketAddress(ipAddress: "::1", port: 80)
        let third = try SocketAddress(unixDomainSocketPath: "/definitely/a/path")

        guard case .v4(let firstAddress) = first else {
            XCTFail("Unable to extract IPv4 address")
            return
        }
        guard case .v6(let secondAddress) = second else {
            XCTFail("Unable to extract IPv6 address")
            return
        }
        guard case .unixDomainSocket(let thirdAddress) = third else {
            XCTFail("Unable to extract UDS address")
            return
        }

        let firstIPAddress = firstAddress.address
        let secondIPAddress = secondAddress.address
        let thirdIPAddress = thirdAddress.address

        first.withSockAddr { outerAddr, outerSize in
            __testOnly_withSockAddr(firstIPAddress) { innerAddr, innerSize in
                XCTAssertEqual(outerSize, innerSize)
                XCTAssertEqual(memcmp(innerAddr, outerAddr, min(outerSize, innerSize)), 0)
                XCTAssertNotEqual(outerAddr, innerAddr)
            }
        }
        second.withSockAddr { outerAddr, outerSize in
            __testOnly_withSockAddr(secondIPAddress) { innerAddr, innerSize in
                XCTAssertEqual(outerSize, innerSize)
                XCTAssertEqual(memcmp(innerAddr, outerAddr, min(outerSize, innerSize)), 0)
                XCTAssertNotEqual(outerAddr, innerAddr)
            }
        }
        third.withSockAddr { outerAddr, outerSize in
            thirdIPAddress.withSockAddr { innerAddr, innerSize in
                XCTAssertEqual(outerSize, innerSize)
                XCTAssertEqual(memcmp(innerAddr, outerAddr, min(outerSize, innerSize)), 0)
                XCTAssertNotEqual(outerAddr, innerAddr)
            }
        }
    }

    func testEqualSocketAddresses() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "00:00::1", port: 80)
        let third = try SocketAddress(ipAddress: "127.0.0.1", port: 443)
        let fourth = try SocketAddress(ipAddress: "127.0.0.1", port: 443)
        let fifth = try SocketAddress(unixDomainSocketPath: "/var/tmp")
        let sixth = try SocketAddress(unixDomainSocketPath: "/var/tmp")

        XCTAssertEqual(first, second)
        XCTAssertEqual(third, fourth)
        XCTAssertEqual(fifth, sixth)
    }

    func testUnequalAddressesOnPort() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "::1", port: 443)
        let third = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        let fourth = try SocketAddress(ipAddress: "127.0.0.1", port: 443)

        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(third, fourth)
    }

    func testUnequalOnAddress() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "::2", port: 80)
        let third = try SocketAddress(ipAddress: "127.0.0.1", port: 443)
        let fourth = try SocketAddress(ipAddress: "127.0.0.2", port: 443)
        let fifth = try SocketAddress(unixDomainSocketPath: "/var/tmp")
        let sixth = try SocketAddress(unixDomainSocketPath: "/var/tmq")

        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(third, fourth)
        XCTAssertNotEqual(fifth, sixth)
    }

    func testHashEqualSocketAddresses() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "00:00::1", port: 80)
        let third = try SocketAddress(ipAddress: "127.0.0.1", port: 443)
        let fourth = try SocketAddress(ipAddress: "127.0.0.1", port: 443)
        let fifth = try SocketAddress(unixDomainSocketPath: "/var/tmp")
        let sixth = try SocketAddress(unixDomainSocketPath: "/var/tmp")

        let set: Set<SocketAddress> = [first, second, third, fourth, fifth, sixth]
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set, [first, third, fifth])
        XCTAssertEqual(set, [second, fourth, sixth])
    }

    func testHashUnequalAddressesOnPort() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "::1", port: 443)
        let third = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        let fourth = try SocketAddress(ipAddress: "127.0.0.1", port: 443)

        let set: Set<SocketAddress> = [first, second, third, fourth]
        XCTAssertEqual(set.count, 4)
    }

    func testHashUnequalOnAddress() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "::2", port: 80)
        let third = try SocketAddress(ipAddress: "127.0.0.1", port: 443)
        let fourth = try SocketAddress(ipAddress: "127.0.0.2", port: 443)
        let fifth = try SocketAddress(unixDomainSocketPath: "/var/tmp")
        let sixth = try SocketAddress(unixDomainSocketPath: "/var/tmq")

        let set: Set<SocketAddress> = [first, second, third, fourth, fifth, sixth]
        XCTAssertEqual(set.count, 6)
    }

    func testUnequalAcrossFamilies() throws {
        let first = try SocketAddress(ipAddress: "::1", port: 80)
        let second = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        let third = try SocketAddress(unixDomainSocketPath: "/var/tmp")

        XCTAssertNotEqual(first, second)
        XCTAssertNotEqual(second, third)
        // By the transitive property first != third, but let's protect against me being an idiot
        XCTAssertNotEqual(third, first)
    }

    func testUnixSocketAddressIgnoresTrailingJunk() throws {
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(NIOBSDSocket.AddressFamily.unix.rawValue)
        let pathBytes: [UInt8] = "/var/tmp".utf8 + [0]

        pathBytes.withUnsafeBufferPointer { srcPtr in
            withUnsafeMutablePointer(to: &addr.sun_path) { dstPtr in
                dstPtr.withMemoryRebound(to: UInt8.self, capacity: srcPtr.count) { dstPtr in
                    dstPtr.assign(from: srcPtr.baseAddress!, count: srcPtr.count)
                }
            }
        }

        let first = SocketAddress(addr)

        // Now poke a random byte at the end. This should be ignored, as that's uninitialized memory.
        addr.sun_path.100 = 60
        let second = SocketAddress(addr)

        XCTAssertEqual(first, second)
        XCTAssertEqual(first.hashValue, second.hashValue)
    }

    func testPortAccessor() throws {
        XCTAssertEqual(try SocketAddress(ipAddress: "127.0.0.1", port: 80).port, 80)
        XCTAssertEqual(try SocketAddress(ipAddress: "::1", port: 80).port, 80)
        XCTAssertEqual(try SocketAddress(unixDomainSocketPath: "/definitely/a/path").port, nil)
    }

    func testCanMutateSockaddrStorage() throws {
        var storage = sockaddr_storage()
        XCTAssertEqual(storage.ss_family, 0)
        __testOnly_withMutableSockAddr(&storage) { (addr, _) in
            addr.pointee.sa_family = sa_family_t(NIOBSDSocket.AddressFamily.unix.rawValue)
        }
        XCTAssertEqual(storage.ss_family, sa_family_t(NIOBSDSocket.AddressFamily.unix.rawValue))
    }

    func testPortIsMutable() throws {
        var ipV4 = try SocketAddress(ipAddress: "127.0.0.1", port: 80)
        var ipV6 = try SocketAddress(ipAddress: "::1", port: 80)
        var unix = try SocketAddress(unixDomainSocketPath: "/definitely/a/path")

        ipV4.port = 81
        ipV6.port = 81

        XCTAssertEqual(ipV4.port, 81)
        XCTAssertEqual(ipV6.port, 81)

        ipV4.port = nil
        ipV6.port = nil
        unix.port = nil

        XCTAssertEqual(ipV4.port, 0)
        XCTAssertEqual(ipV6.port, 0)
        XCTAssertNil(unix.port)
    }
}
