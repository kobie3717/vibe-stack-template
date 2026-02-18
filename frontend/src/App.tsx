import { useEffect, useState, FormEvent } from 'react'

interface Task {
  id: string
  title: string
  description: string
  completed: boolean
  createdAt: string
}

export default function App() {
  const [tasks, setTasks] = useState<Task[]>([])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchTasks = async () => {
    try {
      const res = await fetch('/api/tasks')
      if (!res.ok) throw new Error(`Failed to fetch tasks (${res.status})`)
      setTasks(await res.json())
      setError(null)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchTasks()
  }, [])

  const addTask = async (e: FormEvent) => {
    e.preventDefault()
    if (!title.trim()) return
    try {
      const res = await fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title: title.trim(), description: description.trim() }),
      })
      if (!res.ok) throw new Error('Failed to add task')
      setTitle('')
      setDescription('')
      await fetchTasks()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error')
    }
  }

  const toggleTask = async (task: Task) => {
    try {
      const res = await fetch(`/api/tasks/${task.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ completed: !task.completed }),
      })
      if (!res.ok) throw new Error('Failed to update task')
      await fetchTasks()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error')
    }
  }

  const deleteTask = async (id: string) => {
    try {
      const res = await fetch(`/api/tasks/${id}`, { method: 'DELETE' })
      if (!res.ok) throw new Error('Failed to delete task')
      await fetchTasks()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Unknown error')
    }
  }

  return (
    <div className="container">
      <h1>📋 Task Manager</h1>

      {error && <div className="error">{error}</div>}

      <form className="add-form" onSubmit={addTask}>
        <input
          type="text"
          placeholder="Task title…"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
        <input
          type="text"
          placeholder="Description (optional)"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
        />
        <button type="submit">Add Task</button>
      </form>

      {loading ? (
        <p className="status">Loading tasks…</p>
      ) : tasks.length === 0 ? (
        <p className="status">No tasks yet. Add one above!</p>
      ) : (
        <ul className="task-list">
          {tasks.map((task) => (
            <li key={task.id} className={`task-card${task.completed ? ' completed' : ''}`}>
              <div className="task-content" onClick={() => toggleTask(task)}>
                <span className="checkbox">{task.completed ? '✅' : '⬜'}</span>
                <div>
                  <strong className="task-title">{task.title}</strong>
                  {task.description && <p className="task-desc">{task.description}</p>}
                </div>
              </div>
              <button className="delete-btn" onClick={() => deleteTask(task.id)} title="Delete">
                ✕
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
