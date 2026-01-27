



local Base = {}

function Base.new(Pos : CFrame, Stage : number) : Instance
    assert(Pos ~= nil and Stage ~= nil, 'Values cannot this be nil')
    assert(Stage < 4, 'Internships cannot exceed 3 months.')

    local self = {}

    
    
    return self
end

return Base