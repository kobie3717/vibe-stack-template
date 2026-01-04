/**
 * Shared Types and Contracts
 *
 * This module contains types shared between frontend and backend.
 * Update these when API contracts change, then run `npm run contract:check`.
 */

// ============================================================================
// API Response Envelope
// ============================================================================

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  code?: ErrorCode;
}

export type ErrorCode =
  | 'AUTH_REQUIRED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'VALIDATION_ERROR'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR';

// ============================================================================
// Health Check
// ============================================================================

export interface HealthResponse {
  status: 'ok' | 'degraded' | 'unhealthy';
  timestamp: string;
  version: string;
  checks: {
    database: HealthCheck;
    redis: HealthCheck;
  };
  uptime: number;
}

export interface HealthCheck {
  status: 'ok' | 'error';
  latencyMs?: number;
  error?: string;
}

// ============================================================================
// Authentication
// ============================================================================

export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  user: User;
  token: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
}

// ============================================================================
// Pagination
// ============================================================================

export interface PaginationParams {
  page?: number;
  limit?: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

// ============================================================================
// TODO: Add your domain-specific types below
// ============================================================================

// Example:
// export interface Product {
//   id: string;
//   name: string;
//   price: number;
// }

// export enum ProductStatus {
//   DRAFT = 'DRAFT',
//   ACTIVE = 'ACTIVE',
//   ARCHIVED = 'ARCHIVED',
// }
