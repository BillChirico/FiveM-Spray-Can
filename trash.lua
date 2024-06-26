--[[
private static Vector3 DecalRotationInput(Vector3 direction, float rotationAngle, Entity onEntity = null)
{
 return (Quaternion.RotationAxis(direction, MathUtil.DegreesToRadians(rotationAngle)) * Vector3.ProjectOnPlane(onEntity == null ? new Vector3(0f, 1f, 0f) : onEntity.ForwardVector, direction)).Normalized;
}
]]

local QuatEpsError = 1E-2
function Add(se, vb)
    se.x = se.x + vb.x
    se.y = se.y + vb.y
    se.z = se.z + vb.z

    return se
end

function math.approx(a, b)
	return math.abs(b - a) < math.max(1e-6 * math.max(math.abs(a), math.abs(b)), 1.121039e-44)
end
function math.sign(num)
	if num > 0 then
		num = 1
	elseif num < 0 then
		num = -1
	else
		num = 0
	end

	return num
end
function SurfaceNormalToRightHanded(normal, rot)
    print(rot)
    local rotation
    if math.approx(math.abs(normal.z), 1.0, QuatEpsError) then
        rotation = QuaternionLookRotation(normal, vector3(1,0,0))
    else
        rotation = QuaternionLookRotation(normal, vector3(0,1,0))
    end

    --[[
    The surface is roughly upwards/downwards, rotate the marker in such a
    way that it faces towards the specified camera.
    --]]
    if rot and math.approx(math.abs(normal.z), 1.0, QuatEpsError) then
        print(QuaternionToEuler(rotation).z)
        local offset = math.sign(normal.z) * (rot.z - QuaternionToEuler(rotation).z)
        rotation = QuaternionMul(QuaternionEuler(0.0, 0.0, offset), rotation)
    elseif math.approx(normal.y, 1.0, QuatEpsError) then
        rotation = QuaternionMul(QuaternionEuler(0.0, 180.0, 0.0), rotation)
    end
    return rotation
end
function QuaternionMul(lhs, rhs)
    return vector4((((lhs.w * rhs.x) + (lhs.x * rhs.w)) + (lhs.y * rhs.z)) - (lhs.z * rhs.y), (((lhs.w * rhs.y) + (lhs.y * rhs.w)) + (lhs.z * rhs.x)) - (lhs.x * rhs.z), (((lhs.w * rhs.z) + (lhs.z * rhs.w)) + (lhs.x * rhs.y)) - (lhs.y * rhs.x), (((lhs.w * rhs.w) - (lhs.x * rhs.x)) - (lhs.y * rhs.y)) - (lhs.z * rhs.z))
end


function Cross(lhs, rhs)
    local x = lhs.y * rhs.z - lhs.z * rhs.y
    local y = lhs.z * rhs.x - lhs.x * rhs.z
    local z = lhs.x * rhs.y - lhs.y * rhs.x
    return vector3(x,y,z)
end


local function SanitizeEuler(euler)
    local euler = {x = euler.x, y = euler.y, z = euler.z}
    if euler.x < negativeFlip then
        euler.x = euler.x + two_pi
    elseif euler.x > positiveFlip then
        euler.x = euler.x - two_pi
    end

    if euler.y < negativeFlip then
        euler.y = euler.y + two_pi
    elseif euler.y > positiveFlip then
        euler.y = euler.y - two_pi
    end

    if euler.z < negativeFlip then
        euler.z = euler.z + two_pi
    elseif euler.z > positiveFlip then
        euler.z = euler.z + two_pi
    end
    return euler
end

function QuaternionEuler(x, y, z)
    if y == nil and z == nil then
        y = x.y
        z = x.z
        x = x.x
    end

    x = x * halfDegToRad
    y = y * halfDegToRad
    z = z * halfDegToRad

    local sinX = math.sin(x)
    local cosX = math.cos(x)
    local sinY = math.sin(y)
    local cosY = math.cos(y)
    local sinZ = math.sin(z)
    local cosZ = math.cos(z)

    local se = {}
    se.w = cosY * cosX * cosZ + sinY * sinX * sinZ
    se.x = cosY * sinX * cosZ + sinY * cosX * sinZ
    se.y = sinY * cosX * cosZ - cosY * sinX * sinZ
    se.z = cosY * cosX * sinZ - sinY * sinX * cosZ

    return se
end

function Mul(se, q)
    if type(q) == "number" then
        se.x = se.x * q
        se.y = se.y * q
        se.z = se.z * q
    end

    return se
end

function QuaternionToEuler(se)
    local x = se.x
    local y = se.y
    local z = se.z
    local w = se.w

    local check = 2 * (y * z - w * x)

    if check < 0.999 then
        if check > -0.999 then
            local v = vector3( -math.asin(check),
            math.atan2(2 * (x * z + w * y), 1 - 2 * (x * x + y * y)),
            math.atan2(2 * (x * y + w * z), 1 - 2 * (x * x + z * z)))
            v = SanitizeEuler(v)
            v = Mul(v, rad2Deg)
            return v
        else
            local v = vector3(math.pi*0.5, math.atan2(2 * (x * y - w * z), 1 - 2 * (y * y + z * z)), 0)
            v = SanitizeEuler(v)
            v = Mul(v, rad2Deg)
            return v
        end
    else
        local v = vector3(-math.pi*0.5, math.atan2(-2 * (x * y - w * z), 1 - 2 * (y * y + z * z)), 0)
        v = SanitizeEuler(v)
        v = Mul(v, rad2Deg)
        return v
    end
end

function QuaternionLookRotation(forward, up)
    local mag = math.sqrt(forward.x * forward.x + forward.y * forward.y + forward.z * forward.z)
    if mag < 1e-6 then
        print("error input forward to Quaternion.LookRotation" + tostring(forward))
        return nil
    end

    forward = forward / mag
    up = up or _up
    local right = Cross(up, forward)
    right = SetNormalize(right)
    up = Cross(forward, right)
    right = Cross(up, forward)

    local t = right.x + up.y + forward.z

    if t > 0 then
        local x, y, z, w
        t = t + 1
        local s = 0.5 / math.sqrt(t)
        w = s * t
        x = (up.z - forward.y) * s
        y = (forward.x - right.z) * s
        z = (right.y - up.x) * s

        local ret = {x = x, y = y, z = z, w = w}
        ret = SetNormalize(ret)
        return ret
    else
        local rot =
        {
            {right.x, up.x, forward.x},
            {right.y, up.y, forward.y},
            {right.z, up.z, forward.z},
        }

        local q = {0, 0, 0}
        local i = 1

        if up.y > right.x then
            i = 2
        end

        if forward.z > rot[i][i] then
            i = 3
        end

        local j = _next[i]
        local k = _next[j]

        local t = rot[i][i] - rot[j][j] - rot[k][k] + 1
        local s = 0.5 / math.sqrt(t)
        q[i] = s * t
        local w = (rot[k][j] - rot[j][k]) * s
        q[j] = (rot[j][i] + rot[i][j]) * s
        q[k] = (rot[k][i] + rot[i][k]) * s

        local ret = {x = q[1], y = q[2], z = q[3], w = w}
        ret = SetNormalize(ret)
        return ret
    end
end
