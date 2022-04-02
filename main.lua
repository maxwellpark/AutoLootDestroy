local soulstone_id = 16893;
local max_soulstones = 10; -- Configurable
local soulstone_count = GetItemCount(soulstone_id);
local destroy_count = soulstone_count - max_soulstones;

if player:HasItem(soulstone_id) and soulstone_count > max_soulstones then
    player:RemoveItem(soulstone_id, destroy_count);
end
