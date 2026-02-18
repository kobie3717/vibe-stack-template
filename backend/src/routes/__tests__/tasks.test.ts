import { describe, it, expect, beforeEach } from "vitest";
import request from "supertest";
import app from "../../app.js";
import { clearTasks } from "../tasks.js";

describe("Tasks API", () => {
  beforeEach(() => clearTasks());

  it("GET /api/tasks returns empty list", async () => {
    const res = await request(app).get("/api/tasks");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ success: true, data: [] });
  });

  it("POST /api/tasks creates a task", async () => {
    const res = await request(app)
      .post("/api/tasks")
      .send({ title: "Test task", description: "A desc" });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.title).toBe("Test task");
    expect(res.body.data.completed).toBe(false);
    expect(res.body.data.id).toBeDefined();
  });

  it("POST /api/tasks without title returns 400", async () => {
    const res = await request(app).post("/api/tasks").send({});
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it("GET /api/tasks/:id returns a task", async () => {
    const created = await request(app).post("/api/tasks").send({ title: "X" });
    const res = await request(app).get(`/api/tasks/${created.body.data.id}`);
    expect(res.status).toBe(200);
    expect(res.body.data.title).toBe("X");
  });

  it("GET /api/tasks/:id returns 404 for missing", async () => {
    const res = await request(app).get("/api/tasks/nonexistent");
    expect(res.status).toBe(404);
  });

  it("PATCH /api/tasks/:id updates a task", async () => {
    const created = await request(app).post("/api/tasks").send({ title: "Old" });
    const res = await request(app)
      .patch(`/api/tasks/${created.body.data.id}`)
      .send({ title: "New", completed: true });
    expect(res.status).toBe(200);
    expect(res.body.data.title).toBe("New");
    expect(res.body.data.completed).toBe(true);
  });

  it("DELETE /api/tasks/:id deletes a task", async () => {
    const created = await request(app).post("/api/tasks").send({ title: "Del" });
    const res = await request(app).delete(`/api/tasks/${created.body.data.id}`);
    expect(res.status).toBe(204);
    const check = await request(app).get(`/api/tasks/${created.body.data.id}`);
    expect(check.status).toBe(404);
  });

  it("DELETE /api/tasks/:id returns 404 for missing", async () => {
    const res = await request(app).delete("/api/tasks/nonexistent");
    expect(res.status).toBe(404);
  });
});
