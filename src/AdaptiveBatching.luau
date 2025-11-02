--!strict
--!native
--!optimize 2
-- Ligaya Framework - Adaptive Batching
-- Dynamically adjusts batch size based on network conditions

local AdaptiveBatching = {}
AdaptiveBatching.__index = AdaptiveBatching

-- Network condition thresholds
local LATENCY_LOW = 50 -- ms
local LATENCY_MEDIUM = 100 -- ms
local LATENCY_HIGH = 200 -- ms

local PACKET_LOSS_LOW = 0.01 -- 1%
local PACKET_LOSS_MEDIUM = 0.05 -- 5%
local PACKET_LOSS_HIGH = 0.10 -- 10%

-- Batch size ranges
local BATCH_SIZE_MIN = 300
local BATCH_SIZE_DEFAULT = 900
local BATCH_SIZE_MAX = 1400

function AdaptiveBatching.new()
	local self = setmetatable({}, AdaptiveBatching)

	self._currentBatchSize = BATCH_SIZE_DEFAULT
	self._latencyHistory = {}
	self._packetLossHistory = {}
	self._lastAdjustTime = 0
	self._adjustInterval = 1.0 -- Adjust every 1 second

	self._sentPackets = 0
	self._receivedAcks = 0
	self._lastPacketLossCheck = 0

	return self
end

-- Record latency measurement
function AdaptiveBatching:RecordLatency(latency: number)
	table.insert(self._latencyHistory, latency)

	-- Keep only last 10 measurements
	if #self._latencyHistory > 10 then
		table.remove(self._latencyHistory, 1)
	end
end

-- Record packet sent
function AdaptiveBatching:RecordPacketSent()
	self._sentPackets += 1
end

-- Record packet acknowledged
function AdaptiveBatching:RecordPacketAck()
	self._receivedAcks += 1
end

-- Calculate average latency
function AdaptiveBatching:GetAverageLatency(): number
	if #self._latencyHistory == 0 then
		return 0
	end

	local sum = 0
	for _, latency in self._latencyHistory do
		sum += latency
	end

	return sum / #self._latencyHistory
end

-- Calculate packet loss rate
function AdaptiveBatching:GetPacketLossRate(): number
	if self._sentPackets == 0 then
		return 0
	end

	local lossRate = 1 - (self._receivedAcks / self._sentPackets)
	return math.max(0, lossRate)
end

-- Adjust batch size based on network conditions
function AdaptiveBatching:AdjustBatchSize(currentTime: number)
	-- Only adjust at intervals
	if currentTime - self._lastAdjustTime < self._adjustInterval then
		return
	end

	self._lastAdjustTime = currentTime

	local avgLatency = self:GetAverageLatency()
	local packetLoss = self:GetPacketLossRate()

	-- Determine network quality
	local targetBatchSize = BATCH_SIZE_DEFAULT

	-- Good network: increase batch size
	if avgLatency < LATENCY_LOW and packetLoss < PACKET_LOSS_LOW then
		targetBatchSize = BATCH_SIZE_MAX

	-- Medium network: use default
	elseif avgLatency < LATENCY_MEDIUM and packetLoss < PACKET_LOSS_MEDIUM then
		targetBatchSize = BATCH_SIZE_DEFAULT

	-- Poor network: reduce batch size
	elseif avgLatency < LATENCY_HIGH and packetLoss < PACKET_LOSS_HIGH then
		targetBatchSize = math.floor(BATCH_SIZE_DEFAULT * 0.7)

	-- Very poor network: minimum batch size
	else
		targetBatchSize = BATCH_SIZE_MIN
	end

	-- Smooth transition (don't jump immediately)
	local diff = targetBatchSize - self._currentBatchSize
	self._currentBatchSize = math.floor(self._currentBatchSize + diff * 0.3)

	-- Clamp to valid range
	self._currentBatchSize = math.clamp(self._currentBatchSize, BATCH_SIZE_MIN, BATCH_SIZE_MAX)

	-- Reset packet loss tracking
	if currentTime - self._lastPacketLossCheck > 5.0 then
		self._sentPackets = 0
		self._receivedAcks = 0
		self._lastPacketLossCheck = currentTime
	end
end

-- Get current batch size
function AdaptiveBatching:GetBatchSize(): number
	return self._currentBatchSize
end

-- Get network quality metrics
function AdaptiveBatching:GetMetrics()
	return {
		BatchSize = self._currentBatchSize,
		AverageLatency = self:GetAverageLatency(),
		PacketLossRate = self:GetPacketLossRate(),
		Quality = self:_getQualityString(),
	}
end

function AdaptiveBatching:_getQualityString(): string
	local avgLatency = self:GetAverageLatency()
	local packetLoss = self:GetPacketLossRate()

	if avgLatency < LATENCY_LOW and packetLoss < PACKET_LOSS_LOW then
		return "Excellent"
	elseif avgLatency < LATENCY_MEDIUM and packetLoss < PACKET_LOSS_MEDIUM then
		return "Good"
	elseif avgLatency < LATENCY_HIGH and packetLoss < PACKET_LOSS_HIGH then
		return "Fair"
	else
		return "Poor"
	end
end

return AdaptiveBatching
