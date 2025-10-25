//
//  Config.swift
//  Your Daily Dose
//
//  Configuration for API endpoints and credentials
//

import Foundation

struct Config {
    // MARK: - Supabase Configuration
    
    /// Supabase Project URL
    /// TODO: Replace with your actual Supabase project URL from https://app.supabase.com
    /// Format: https://[project-ref].supabase.co
    static let supabaseURL = "https://bkjfyxfphwhwwonmbulj.supabase.co"
    
    /// Supabase Anonymous (Public) Key
    /// TODO: Replace with your actual anon key from Project Settings > API
    /// This is safe to include in client apps
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJramZ5eGZwaHdod3dvbm1idWxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyMDUxMzMsImV4cCI6MjA3MTc4MTEzM30.UCySNkl1qbBgPtN1TQynImtWdI-LQ5mv8T-SGmYUVJQ"
    
    // MARK: - Backend API Configuration
    
    /// Backend API Base URL
    /// For local development: http://localhost:3000
    /// For production: Your deployed backend URL
    static var backendURL: String {
        #if DEBUG
        return "http://localhost:3000"
        #else
        // TODO: Replace with your production backend URL
        return "https://your-backend.onrender.com"
        #endif
    }
    
    // MARK: - OAuth Configuration
    
    /// OAuth callback URL scheme
    static let oauthCallbackScheme = "dailyritual"
    
    /// OAuth callback path
    static let oauthCallbackPath = "auth-callback"
    
    // MARK: - Feature Flags
    
    /// Use mock authentication for development
    static let useMockAuth = false
    
    /// Enable debug logging
    static var enableDebugLogging: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Helper Extensions

extension Config {
    /// Full auth endpoint URL
    static var authEndpoint: String {
        return "\(supabaseURL)/auth/v1"
    }
    
    /// Full rest endpoint URL
    static var restEndpoint: String {
        return "\(supabaseURL)/rest/v1"
    }
    
    /// Full functions endpoint URL
    static var functionsEndpoint: String {
        return "\(supabaseURL)/functions/v1"
    }
}

