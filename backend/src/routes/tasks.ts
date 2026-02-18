import { Router, type Request, type Response } from "express";
import { randomUUID } from "crypto";

interface Task {
  id: string;
  title: string;
  description: string;
  completed: boolean;
  createdAt: string;
  updatedAt: string;
}

const tasks: Map<string, Task> = new Map();

export function clearTasks() {
  tasks.clear();
}

export const taskRouter = Router();

taskRouter.get("/", (_req: Request, res: Response) => {
  res.json({ success: true, data: Array.from(tasks.values()) });
});

taskRouter.post("/", (req: Request, res: Response) => {
  const { title, description } = req.body;
  if (!title || typeof title !== "string" || !title.trim()) {
    res.status(400).json({ success: false, error: "title is required" });
    return;
  }
  const now = new Date().toISOString();
  const task: Task = {
    id: randomUUID(),
    title: title.trim(),
    description: typeof description === "string" ? description : "",
    completed: false,
    createdAt: now,
    updatedAt: now,
  };
  tasks.set(task.id, task);
  res.status(201).json({ success: true, data: task });
});

taskRouter.get("/:id", (req: Request<{ id: string }>, res: Response) => {
  const task = tasks.get(req.params.id);
  if (!task) {
    res.status(404).json({ success: false, error: "Task not found" });
    return;
  }
  res.json({ success: true, data: task });
});

taskRouter.patch("/:id", (req: Request<{ id: string }>, res: Response) => {
  const task = tasks.get(req.params.id);
  if (!task) {
    res.status(404).json({ success: false, error: "Task not found" });
    return;
  }
  const { title, description, completed } = req.body;
  if (title !== undefined) task.title = String(title).trim();
  if (description !== undefined) task.description = String(description);
  if (completed !== undefined) task.completed = Boolean(completed);
  task.updatedAt = new Date().toISOString();
  res.json({ success: true, data: task });
});

taskRouter.delete("/:id", (req: Request<{ id: string }>, res: Response) => {
  if (!tasks.has(req.params.id)) {
    res.status(404).json({ success: false, error: "Task not found" });
    return;
  }
  tasks.delete(req.params.id);
  res.status(204).send();
});
