// UseCaseable.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

public protocol Usecaseable {
    associatedtype Parameter
    associatedtype Result
    associatedtype Execution
    var execute: Execution { get }
}
