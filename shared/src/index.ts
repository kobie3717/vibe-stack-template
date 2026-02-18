// Task types shared between frontend and backend
export interface Task {
  id: string;
  title: string;
  description: string;
  completed: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateTaskInput {
  title: string;
  description?: string;
}

export interface UpdateTaskInput {
  title?: string;
  description?: string;
  completed?: boolean;
}

// API response envelope
export interface ApiResponse<T> {
  success: true;
  data: T;
}

export interface ApiError {
  success: false;
  error: string;
  code?: string;
}

export type ApiResult<T> = ApiResponse<T> | ApiError;
