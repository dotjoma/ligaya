--!strict
-- Ligaya Framework - Metrics Collection
-- Performance monitoring and analytics

local Types = require(script.Parent.Types)

type NetworkMetrics = Types.NetworkMetrics
type EventMetrics = Types.EventMetrics

local MetricsCollector = {}
MetricsCollector.__index = MetricsCollector

function MetricsCollector.new()
	local self = setmetatable({}, MetricsCollector)

	self._globalMetrics = {
		EventsSent = 0,
		EventsReceived = 0,
		BytesSent = 0,
		BytesReceived = 0,
		AverageLatency = 0,
		PacketLoss = 0,
		CompressionRatio = 1.0,
		ErrorCount = 0,
	}

	self._eventMetrics = {}
	self._latencySamples = {}
	self._maxSamples = 100

	return self :: any
end

function MetricsCollector:RecordEventSent(eventName: string, bytes: number)
	self._globalMetrics.EventsSent += 1
	self._globalMetrics.BytesSent += bytes

	self:_updateEventMetrics(eventName, bytes)
end

function MetricsCollector:RecordEventReceived(eventName: string, bytes: number)
	self._globalMetrics.EventsReceived += 1
	self._globalMetrics.BytesReceived += bytes

	self:_updateEventMetrics(eventName, bytes)
end

function MetricsCollector:RecordLatency(latency: number)
	table.insert(self._latencySamples, latency)

	-- Keep only recent samples
	if #self._latencySamples > self._maxSamples then
		table.remove(self._latencySamples, 1)
	end

	-- Calculate average
	local sum = 0
	for _, sample in self._latencySamples do
		sum += sample
	end
	self._globalMetrics.AverageLatency = sum / #self._latencySamples
end

function MetricsCollector:RecordError(eventName: string?)
	self._globalMetrics.ErrorCount += 1

	if eventName and self._eventMetrics[eventName] then
		self._eventMetrics[eventName].Errors += 1
	end
end

function MetricsCollector:RecordCompression(originalSize: number, compressedSize: number)
	if originalSize > 0 then
		local ratio = compressedSize / originalSize
		-- Exponential moving average
		self._globalMetrics.CompressionRatio = self._globalMetrics.CompressionRatio * 0.9 + ratio * 0.1
	end
end

function MetricsCollector:GetGlobalMetrics(): NetworkMetrics
	return table.clone(self._globalMetrics)
end

function MetricsCollector:GetEventMetrics(eventName: string): EventMetrics?
	local metrics = self._eventMetrics[eventName]
	return metrics and table.clone(metrics) or nil
end

function MetricsCollector:GetAllEventMetrics(): { [string]: EventMetrics }
	local result = {}
	for name, metrics in self._eventMetrics do
		result[name] = table.clone(metrics)
	end
	return result
end

function MetricsCollector:Reset()
	self._globalMetrics = {
		EventsSent = 0,
		EventsReceived = 0,
		BytesSent = 0,
		BytesReceived = 0,
		AverageLatency = 0,
		PacketLoss = 0,
		CompressionRatio = 1.0,
		ErrorCount = 0,
	}

	table.clear(self._eventMetrics)
	table.clear(self._latencySamples)
end

function MetricsCollector:_updateEventMetrics(eventName: string, bytes: number)
	if not self._eventMetrics[eventName] then
		self._eventMetrics[eventName] = {
			CallCount = 0,
			TotalBytes = 0,
			AverageSize = 0,
			LastCalled = 0,
			Errors = 0,
		}
	end

	local metrics = self._eventMetrics[eventName]
	metrics.CallCount += 1
	metrics.TotalBytes += bytes
	metrics.AverageSize = metrics.TotalBytes / metrics.CallCount
	metrics.LastCalled = os.clock()
end

-- Utility function to format metrics for display
function MetricsCollector:FormatMetrics(): string
	local global = self._globalMetrics
	local avgLatencyMs = string.format("%.2f", global.AverageLatency * 1000)
	local compressionPct = string.format("%.1f", global.CompressionRatio * 100)

	local lines = {
		"=== Ligaya Network Metrics ===",
		`Events: {global.EventsSent} sent, {global.EventsReceived} received`,
		`Bandwidth: {self:_formatBytes(global.BytesSent)} sent, {self:_formatBytes(global.BytesReceived)} received`,
		`Latency: {avgLatencyMs}ms average`,
		`Compression: {compressionPct}% of original size`,
		`Errors: {global.ErrorCount}`,
		"",
		"=== Per-Event Metrics ===",
	}

	for name, metrics in self._eventMetrics do
		table.insert(lines, `{name}: {metrics.CallCount} calls, {self:_formatBytes(metrics.AverageSize)} avg`)
	end

	return table.concat(lines, "\n")
end

function MetricsCollector:_formatBytes(bytes: number): string
	if bytes < 1024 then
		return `{bytes}B`
	elseif bytes < 1024 * 1024 then
		local kb = string.format("%.2f", bytes / 1024)
		return `{kb}KB`
	else
		local mb = string.format("%.2f", bytes / (1024 * 1024))
		return `{mb}MB`
	end
end

return MetricsCollector
