-- Hitbox Exclusions Module
-- Centralized exclusion system for hitbox targeting

local CollectionService = game:GetService("CollectionService")

local HitboxExclusions = {}

-- Global exclusion tags - add any tags you want hitboxes to ignore
HitboxExclusions.EXCLUDE_TAGS = {
    "golem_entity",
    "spider_entity",
    "simple_entity"
}

-- Function to check if a model has any excluded tags
function HitboxExclusions.hasExcludedTag(model)
    for _, tag in ipairs(HitboxExclusions.EXCLUDE_TAGS) do
        if CollectionService:HasTag(model, tag) then
            return true
        end
    end
    return false
end

-- Function to add a new exclusion tag
function HitboxExclusions.addExclusionTag(tag)
    table.insert(HitboxExclusions.EXCLUDE_TAGS, tag)
end

-- Function to remove an exclusion tag
function HitboxExclusions.removeExclusionTag(tag)
    for i, existingTag in ipairs(HitboxExclusions.EXCLUDE_TAGS) do
        if existingTag == tag then
            table.remove(HitboxExclusions.EXCLUDE_TAGS, i)
            break
        end
    end
end

-- Function to get all exclusion tags
function HitboxExclusions.getExclusionTags()
    return HitboxExclusions.EXCLUDE_TAGS
end

return HitboxExclusions
