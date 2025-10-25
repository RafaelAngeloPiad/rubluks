-- Mob Exclusions Module
-- Centralized exclusion system for all mob AI

local CollectionService = game:GetService("CollectionService")

local MobExclusions = {}

-- Global exclusion tags - add any tags you want mobs to ignore
MobExclusions.EXCLUDE_TAGS = {
    "golem_entity",
    "spider_entity",
}

-- Function to check if a model has any excluded tags
function MobExclusions.hasExcludedTag(model)
    for _, tag in ipairs(MobExclusions.EXCLUDE_TAGS) do
        if CollectionService:HasTag(model, tag) then
            return true
        end
    end
    return false
end

-- Function to add a new exclusion tag
function MobExclusions.addExclusionTag(tag)
    table.insert(MobExclusions.EXCLUDE_TAGS, tag)
end

-- Function to remove an exclusion tag
function MobExclusions.removeExclusionTag(tag)
    for i, existingTag in ipairs(MobExclusions.EXCLUDE_TAGS) do
        if existingTag == tag then
            table.remove(MobExclusions.EXCLUDE_TAGS, i)
            break
        end
    end
end

-- Function to get all exclusion tags
function MobExclusions.getExclusionTags()
    return MobExclusions.EXCLUDE_TAGS
end

return MobExclusions
