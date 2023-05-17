// AsyncUseCaseable.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

public protocol AsyncUsecaseable {
    associatedtype Parameter: Sendable
    associatedtype Result: Sendable
    associatedtype Execution: Sendable
    var execute: Execution { get }
}
