// AsyncExecutables.swift
//
// Copyright (c) 2022-2023 Gabor Nagy
// Created by gabor.nagy.0814@gmail.com on 2022. 12. 28..

import Foundation

public typealias AsyncExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) async -> Result
public typealias AsyncThrowingExecutable<Parameter: Sendable, Result: Sendable> = @Sendable (Parameter) async throws -> Result
