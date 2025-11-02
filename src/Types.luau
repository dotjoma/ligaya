--!strict
-- Ligaya Framework - Core Type Definitions
-- Comprehensive type system for the networking framework

export type Priority = "Low" | "Normal" | "High" | "Critical"

export type EventType = "Reliable" | "Unreliable"

export type CallType = "SingleSync" | "ManySync" | "SingleAsync" | "ManyAsync" | "Polling"

export type Direction = "Server" | "Client"

-- Buffer management types
export type BufferPool = {
	Acquire: (size: number) -> buffer,
	Release: (buf: buffer) -> (),
	Clear: () -> (),
	GetStats: () -> BufferPoolStats,
}

export type BufferPoolStats = {
	TotalBuffers: number,
	ActiveBuffers: number,
	PoolHits: number,
	PoolMisses: number,
}

-- Middleware types
export type MiddlewareContext = {
	Player: Player?,
	EventName: string,
	Data: any,
	Metadata: { [string]: any },
	Cancel: () -> (),
	IsCancelled: boolean,
}

export type Middleware = (context: MiddlewareContext, next: () -> ()) -> ()

export type MiddlewarePipeline = {
	Use: (middleware: Middleware) -> (),
	Execute: (context: MiddlewareContext) -> boolean,
	Clear: () -> (),
}

-- Event configuration
export type EventConfig = {
	Name: string,
	From: Direction,
	Type: EventType,
	Call: CallType,
	Priority: Priority?,
	Compress: boolean?,
	MaxSize: number?,
	RateLimit: RateLimitConfig?,
	UseDeltaCompression: boolean?, -- New: Enable delta compression
	UseAdaptiveBatching: boolean?, -- New: Enable adaptive batching
}

export type RateLimitConfig = {
	MaxCalls: number,
	WindowSeconds: number,
}

-- Metrics and monitoring
export type NetworkMetrics = {
	EventsSent: number,
	EventsReceived: number,
	BytesSent: number,
	BytesReceived: number,
	AverageLatency: number,
	PacketLoss: number,
	CompressionRatio: number,
	ErrorCount: number,
	DeltaCompressionSavings: number?, -- New: Bytes saved by delta compression
	AdaptiveBatchSize: number?, -- New: Current adaptive batch size
	NetworkQuality: string?, -- New: Network quality rating
}

export type EventMetrics = {
	CallCount: number,
	TotalBytes: number,
	AverageSize: number,
	LastCalled: number,
	Errors: number,
}

-- Serialization types
export type Serializer = {
	Serialize: (data: any) -> buffer,
	Deserialize: (buf: buffer) -> any,
}

export type CompressionStrategy = {
	Compress: (data: buffer) -> buffer,
	Decompress: (data: buffer) -> buffer,
	ShouldCompress: (size: number) -> boolean,
}

-- Queue types
export type PriorityQueue<T> = {
	Enqueue: (item: T, priority: Priority) -> (),
	Dequeue: () -> T?,
	Peek: () -> T?,
	Size: () -> number,
	Clear: () -> (),
}

export type QueueEntry<T> = {
	Value: T,
	Priority: number,
	Timestamp: number,
}

-- Retry logic
export type RetryConfig = {
	MaxAttempts: number,
	InitialDelay: number,
	MaxDelay: number,
	BackoffMultiplier: number,
}

export type RetryableOperation = {
	Execute: () -> boolean,
	OnSuccess: (() -> ())?,
	OnFailure: ((error: string) -> ())?,
	Config: RetryConfig,
}

-- Event handler types
export type EventHandler = (...any) -> ()

export type EventConnection = {
	Disconnect: () -> (),
	Connected: boolean,
}

-- Network packet structure
export type NetworkPacket = {
	EventIndex: number,
	Priority: number,
	Timestamp: number,
	Compressed: boolean,
	DataSize: number,
	Data: buffer,
	Instances: { Instance }?,
}

return nil
