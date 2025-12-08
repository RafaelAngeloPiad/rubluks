-- chat_command_filter.server.luau
-- Centralized chat filter to hide all messages starting with "/" from other players
-- This prevents passwords and commands from being visible in chat while still allowing
-- server-side command scripts to process them via player.Chatted events

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

print("[ChatCommandFilter] Initializing chat command filter...")

-- Wait for TextChatService to be ready
task.wait(1)

-- Check which chat system is being used
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	print("[ChatCommandFilter] Using TextChatService (new chat system)")
	
	-- Get the general channel
	local success, result = pcall(function()
		local textChannels = TextChatService:WaitForChild("TextChannels", 10)
		if not textChannels then
			warn("[ChatCommandFilter] TextChannels not found!")
			return false
		end
		
		local generalChannel = textChannels:FindFirstChild("RBXGeneral")
		if not generalChannel then
			warn("[ChatCommandFilter] RBXGeneral channel not found!")
			return false
		end
		
		-- Use ShouldDeliverCallback to filter who receives the message
		generalChannel.ShouldDeliverCallback = function(message: TextChatMessage, targetTextSource: TextSource)
			-- Get the sender's TextSource
			local senderTextSource = message.TextSource
			
			-- Check if the message starts with "/"
			if message.Text and string.sub(message.Text, 1, 1) == "/" then
				-- Only deliver the message to the sender themselves
				-- This way they see their own command but others don't
				if targetTextSource == senderTextSource then
					return true -- Deliver to sender
				else
					return false -- Don't deliver to other players
				end
			end
			
			-- For normal messages, deliver to everyone
			return true
		end
		
		print("[ChatCommandFilter] Successfully registered ShouldDeliverCallback!")
		return true
	end)
	
	if not success then
		warn("[ChatCommandFilter] Failed to setup filter:", result)
	end
	
else
	-- Legacy chat system
	print("[ChatCommandFilter] Using legacy chat system")
	
	local Chat = game:GetService("Chat")
	
	local function shouldFilterMessage(speaker, message, channelName)
		-- Check if message starts with "/"
		if string.sub(message, 1, 1) == "/" then
			print("[ChatCommandFilter] Filtered command (legacy):", message)
			return true
		end
		return false
	end
	
	local success, errorMessage = pcall(function()
		Chat:RegisterProcessCommandsFunction(shouldFilterMessage)
	end)
	
	if success then
		print("[ChatCommandFilter] Successfully registered with legacy ChatService!")
	else
		warn("[ChatCommandFilter] Failed to register legacy chat filter:", errorMessage)
	end
end

print("[ChatCommandFilter] Chat command filter is active. Messages starting with '/' will only be visible to the sender.")

