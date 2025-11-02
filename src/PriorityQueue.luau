--!strict
-- Ligaya Framework - Priority Queue Implementation
-- Min-heap based priority queue for event scheduling

local Types = require(script.Parent.Types)

type Priority = Types.Priority
type PriorityQueue<T> = Types.PriorityQueue<T>
type QueueEntry<T> = Types.QueueEntry<T>

local PRIORITY_VALUES = {
	Critical = 0,
	High = 1,
	Normal = 2,
	Low = 3,
}

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new<T>(): PriorityQueue<T>
	local self = setmetatable({}, PriorityQueue)
	self._heap = {}
	self._size = 0
	return self :: any
end

-- Helper functions for heap operations
local function parent(i: number): number
	return math.floor(i / 2)
end

local function leftChild(i: number): number
	return 2 * i
end

local function rightChild(i: number): number
	return 2 * i + 1
end

local function swap(heap: any, i: number, j: number)
	heap[i], heap[j] = heap[j], heap[i]
end

local function heapifyUp(heap: any, index: number)
	while index > 1 do
		local p = parent(index)
		local current = heap[index]
		local parentNode = heap[p]

		-- Compare priority first, then timestamp for FIFO within same priority
		if
			current.Priority < parentNode.Priority
			or (current.Priority == parentNode.Priority and current.Timestamp < parentNode.Timestamp)
		then
			swap(heap, index, p)
			index = p
		else
			break
		end
	end
end

local function heapifyDown(heap: any, index: number, size: number)
	while true do
		local smallest = index
		local left = leftChild(index)
		local right = rightChild(index)

		if left <= size then
			local leftNode = heap[left]
			local smallestNode = heap[smallest]
			if
				leftNode.Priority < smallestNode.Priority
				or (leftNode.Priority == smallestNode.Priority and leftNode.Timestamp < smallestNode.Timestamp)
			then
				smallest = left
			end
		end

		if right <= size then
			local rightNode = heap[right]
			local smallestNode = heap[smallest]
			if
				rightNode.Priority < smallestNode.Priority
				or (rightNode.Priority == smallestNode.Priority and rightNode.Timestamp < smallestNode.Timestamp)
			then
				smallest = right
			end
		end

		if smallest ~= index then
			swap(heap, index, smallest)
			index = smallest
		else
			break
		end
	end
end

function PriorityQueue:Enqueue(item: any, priority: Priority)
	local priorityValue = PRIORITY_VALUES[priority] or PRIORITY_VALUES.Normal

	local entry = {
		Value = item,
		Priority = priorityValue,
		Timestamp = os.clock(),
	}

	self._size += 1
	self._heap[self._size] = entry
	heapifyUp(self._heap, self._size)
end

function PriorityQueue:Dequeue(): any?
	if self._size == 0 then
		return nil
	end

	local root = self._heap[1]
	self._heap[1] = self._heap[self._size]
	self._heap[self._size] = nil
	self._size -= 1

	if self._size > 0 then
		heapifyDown(self._heap, 1, self._size)
	end

	return root.Value
end

function PriorityQueue:Peek(): any?
	if self._size == 0 then
		return nil
	end
	return self._heap[1].Value
end

function PriorityQueue:Size(): number
	return self._size
end

function PriorityQueue:Clear()
	table.clear(self._heap)
	self._size = 0
end

return PriorityQueue
