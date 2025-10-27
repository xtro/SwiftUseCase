// SwiftUseCaseTests.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

@testable import SwiftUseCase
import Testing
import Foundation

fileprivate struct AddUseCase: UseCase {
    typealias Parameter = (Int, Int)
    typealias Result = Int
    let execute: Executable<Parameter, Result> = { param in param.0 + param.1 }
}

fileprivate struct AddAsyncUseCase: AsyncUseCase {
    typealias Parameter = (Int, Int)
    typealias Result = Int
    let execute: AsyncExecutable<Parameter, Result> = { param in param.0 + param.1 }
}

fileprivate struct AddThrowingUseCase: ThrowingUseCase {
    typealias Parameter = (Int, Int)
    typealias Result = Int
    enum Failure: Error { case fail }
    let execute: ThrowingExecutable<Parameter, Result> = { param in
        if param.0 < 0 || param.1 < 0 { throw Failure.fail }
        return param.0 + param.1
    }
}

fileprivate struct AddAsyncThrowingUseCase: AsyncThrowingUseCase {
    typealias Parameter = (Int, Int)
    typealias Result = Int
    enum Failure: Error { case fail }
    let execute: AsyncThrowingExecutable<Parameter, Result> = { param in
        if param.0 < 0 || param.1 < 0 { throw Failure.fail }
        return param.0 + param.1
    }
}

@Suite("SwiftUseCase basic tests")
struct SwiftUseCaseTests {
    @Test("sync use case callAsFunction")
    func testSyncCall() {
        let usecase = AddUseCase()
        #expect(usecase((1, 2)) == 3)
    }
    @Test("sync use case callAsFunction void")
    func testSyncCallVoid() {
        struct VoidUseCase: UseCase {
            typealias Parameter = Void
            typealias Result = String
            let execute: Executable<Parameter, Result> = { _ in "ok" }
        }
        let usecase = VoidUseCase()
        #expect(usecase() == "ok")
    }
    @Test("async use case callAsFunction")
    func testAsyncCall() async {
        let usecase = AddAsyncUseCase()
        let result = await usecase((2, 3))
        #expect(result == 5)
    }
    @Test("async use case callAsFunction void")
    func testAsyncCallVoid() async {
        struct VoidAsyncUseCase: AsyncUseCase {
            typealias Parameter = Void
            typealias Result = String
            let execute: AsyncExecutable<Parameter, Result> = { _ in "ok" }
        }
        let usecase = VoidAsyncUseCase()
        let result = await usecase()
        #expect(result == "ok")
    }
    @Test("throwing use case callAsFunction")
    func testThrowingCall() throws {
        let usecase = AddThrowingUseCase()
        #expect(try usecase((3, 4)) == 7)
    }
    @Test("throwing use case throws")
    func testThrowingThrows() {
        let usecase = AddThrowingUseCase()
        do {
            _ = try usecase((-1, 1))
            #expect(Bool(false), "Should throw")
        } catch AddThrowingUseCase.Failure.fail {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false), "Wrong error")
        }
    }
    @Test("throwing use case callAsFunction void")
    func testThrowingCallVoid() throws {
        struct VoidThrowingUseCase: ThrowingUseCase {
            typealias Parameter = Void
            typealias Result = String
            let execute: ThrowingExecutable<Parameter, Result> = { _ in "ok" }
        }
        let usecase = VoidThrowingUseCase()
        #expect(try usecase() == "ok")
    }
    @Test("async throwing use case callAsFunction")
    func testAsyncThrowingCall() async throws {
        let usecase = AddAsyncThrowingUseCase()
        #expect(try await usecase((5, 6)) == 11)
    }
    @Test("async throwing use case throws")
    func testAsyncThrowingThrows() async {
        let usecase = AddAsyncThrowingUseCase()
        do {
            _ = try await usecase((-1, 1))
            #expect(Bool(false))
        } catch AddAsyncThrowingUseCase.Failure.fail {
            #expect(Bool(true))
        } catch {
            #expect(Bool(false))
        }
    }
    @Test("async throwing use case callAsFunction void")
    func testAsyncThrowingCallVoid() async throws {
        struct VoidAsyncThrowingUseCase: AsyncThrowingUseCase {
            typealias Parameter = Void
            typealias Result = String
            let execute: AsyncThrowingExecutable<Parameter, Result> = { _ in "ok" }
        }
        let usecase = VoidAsyncThrowingUseCase()
        #expect(try await usecase() == "ok")
    }
    @Test("capitalizedFirstLetter extension")
    func testCapitalizedFirstLetter() {
        #expect("abc".capitalizedFirstLetter == "Abc")
        #expect("Abc".capitalizedFirstLetter == "Abc")
        #expect("".capitalizedFirstLetter == "")
    }
}

fileprivate extension String {
    var capitalizedFirstLetter: String {
        prefix(1).capitalized + dropFirst()
    }
}
