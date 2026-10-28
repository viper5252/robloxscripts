local ScientificTargetPredictor = {}
ScientificTargetPredictor.__index = ScientificTargetPredictor

function ScientificTargetPredictor.new(projectileSpeed)
    return setmetatable({
        ProjectileSpeed = projectileSpeed,
        HistoryPositions = {},
        HistoryTimestamps = {}
    }, ScientificTargetPredictor)
end

function ScientificTargetPredictor:UpdateTargetState(position, timestamp)
    assert(typeof(position) == "Vector3", "Position must be a Vector3")

    timestamp = timestamp or os.clock()

    table.insert(self.HistoryPositions, position)
    table.insert(self.HistoryTimestamps, timestamp)

    if #self.HistoryPositions > 5 then
        table.remove(self.HistoryPositions, 1)
        table.remove(self.HistoryTimestamps, 1)
    end
end

function ScientificTargetPredictor:CalculateInterception(origin)
    origin = origin or Vector3.zero

    local positions = self.HistoryPositions
    local timestamps = self.HistoryTimestamps

    if #positions < 2 then
        return nil
    end

    local current = positions[#positions]
    local previous = positions[#positions - 1]

    local dt = timestamps[#timestamps] - timestamps[#timestamps - 1]

    if dt <= 0 then
        return nil
    end

    local velocity = (current - previous) / dt
    local displacement = current - origin

    local a = velocity:Dot(velocity) - self.ProjectileSpeed ^ 2
    local b = 2 * velocity:Dot(displacement)
    local c = displacement:Dot(displacement)

    local discriminant = b ^ 2 - 4 * a * c

    if discriminant < 0 then
        return nil
    end

    local t

    if math.abs(a) < 1e-8 then
        if math.abs(b) < 1e-8 then
            return nil
        end

        t = -c / b
        if t <= 0 then
            return nil
        end
    else
        local sqrtD = math.sqrt(discriminant)
        local t1 = (-b + sqrtD) / (2 * a)
        local t2 = (-b - sqrtD) / (2 * a)

        if t1 > 0 then t = t1 end
        if t2 > 0 and (not t or t2 < t) then
            t = t2
        end

        if not t then
            return nil
        end
    end

    return {
        PredictedPosition = current + velocity * t,
        TimeToIntercept = t,
        TargetVelocity = velocity
    }
end

-- Example usage
local predictor = ScientificTargetPredictor.new(25)

predictor:UpdateTargetState(Vector3.new(0, 10, 5), 0)
predictor:UpdateTargetState(Vector3.new(1, 10.4, 5), 0.2)
predictor:UpdateTargetState(Vector3.new(2, 10.8, 5), 0.4)
predictor:UpdateTargetState(Vector3.new(3, 11.2, 5), 0.6)

local result = predictor:CalculateInterception(Vector3.zero)

if result then
    print("Predicted position:", result.PredictedPosition)
    print("Time to intercept:", result.TimeToIntercept)
    print("Target velocity:", result.TargetVelocity)
else
    print("No valid interception solution")
end

return ScientificTargetPredictor
