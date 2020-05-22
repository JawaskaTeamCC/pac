-----
-- Math utilities for vector calculus.
-----
local class, operator
do
  local pandora = require './pandora'
  class = pandora.class
  operator = pandora.operator
end

local function badVectorArithmeticError(other)
  error('Cannot do vector arithmetic on ' .. type(other))
end

---
-- 3D basic fast math vector.
-- This is a 3 component only, unaligned vector.
-- For matrix multiplication you could use row/column vectors or other types,
-- which are slower but more reliable for transforms.
-- This vector is intended for fast and simple spatial operations.
---
local Vector
Vector = class 'Vector' {
  x = 0,
  y = 0,
  z = 0,

  Vector = function(this, x, y, z)
    this.x = x
    this.y = y or x
    this.z = z or y or x
  end,

  ---
  -- Sum operator.
  -- If the other element is a scalar it adds the scalar to all components.
  -- Vectors MUST match arity.
  ---
  [operator'+'] = function(this, other)
    if type(other) == 'number' then
      return this:scalarSum(other)
    elseif type(other) == 'table' then
      return this:vectorSum(other)
    else
      badVectorArithmeticError(other)
    end
  end,

  ---
  -- Subtract operator.
  -- If the other element is a scalar it subtracts the scalar to all components.
  -- Vectors MUST match arity.
  ---
  [operator'-'] = function(this, other)
    if type(other) == 'number' then
      return this:scalarSub(other)
    elseif type(other) == 'table' then
      return this:vectorSub(other)
    else
      badVectorArithmeticError(other)
    end
  end,

  ---
  -- Explicit vector sum.
  -- Can be used in places where timing is critical and the input is well-known.
  ---
  vectorSum = function(this, other)
    return Vector(this.x + other.x, this.y + other.y, this.z + other.z)
  end,

  ---
  -- Adds the scalar to all components.
  ---
  scalarSum = function(this, other)
    return Vector(this.x + other, this.y + other, this.z + other)
  end,

  ---
  -- Explicit vector subtract.
  -- Can be used in places where timing is critical and the input is well-known.
  ---
  vectorSub = function(this, other)
    return Vector(this.x - other.x, this.y - other.y, this.z - other.z)
  end,

  ---
  -- Subtracts the scalar to all components.
  ---
  scalarSub = function(this, other)
    return Vector(this.x - other, this.y - other, this.z - other)
  end,

  ---
  -- Returns the product of the two elements.
  -- If the other element is a vector, performs cross/vector product.
  ---
  [operator'*'] = function(this, other)
    if type(other) == 'number' then
      return Vector(this.x * other, this.y * other, this.z * other)
    elseif type(other) == 'table' then
      return this:vectorProduct(other)
    else
      badVectorArithmeticError(other)
    end
  end,

  [operator'(-)'] = function(this)
    return Vector(-this.x, -this.y, -this.z)
  end,

  ---
  -- Dot product, returns a scalar.
  ---
  dotProduct = function(this, other)
    return this.x * other.x + this.y * other.y + this.z * other.z
  end,
  
  ---
  -- Returns the orthogonal vector of the two vectors.
  ---
  vectorProduct = function(this, other)
    return Vector(
      this.y * other.z - this.z * other.y,
      this.z * other.x - this.x * other.z,
      this.x * other.y - this.y * other.x
    )
  end,

  ---
  -- Used to override length getter.
  ---
  length = function(this)
    return math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z)
  end,

  [operator'string'] = function(this)
    return '[ ' .. this.x .. ' ' .. this.y .. ' ' .. this.z .. ' ]'
  end
}

return Vector
