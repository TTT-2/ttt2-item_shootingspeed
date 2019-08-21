ITEM.hud = Material("vgui/ttt/perks/hud_shootingspeed.png")
ITEM.EquipMenuData = {
	type = "item_passive",
	name = "shootingspeed",
	desc = "You shoot 30% faster!"
}
ITEM.material = "vgui/ttt/icon_shootingspeed"
ITEM.notBuyable = true
ITEM.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

if SERVER then
	AddCSLuaFile()

	if ITEM.material then
		resource.AddFile("materials/" .. ITEM.material .. ".vmt")
	end

	if ITEM.Icon then
		resource.AddFile("materials/" .. ITEM.Icon)
	end

	util.AddNetworkString("ShootingSpeed")
end

if SERVER then
	local function DisableWeaponSpeed(wep)
		if IsValid(wep) and wep.OldOnDrop then
			wep.Primary.Delay = wep.OldDelay
			wep.OnDrop = wep.OldOnDrop

			net.Start("ShootingSpeed")
			net.WriteBool(false)
			net.WriteEntity(wep)
			net.WriteFloat(wep.Primary.Delay)
			net.WriteFloat(wep.OldDelay)
			net.Send(wep.Owner)

			wep.OldOnDrop = nil
			wep.OldDelay = nil
		end
	end

	local function ApplyWeaponSpeed(wep)
		if (wep.Kind == WEAPON_HEAVY or wep.Kind == WEAPON_PISTOL) then
			local delay = math.Round(wep.Primary.Delay / 1.5, 3)

			wep.OldDelay = wep.Primary.Delay
			wep.Primary.Delay = delay
			wep.OldOnDrop = wep.OnDrop

			wep.OnDrop = function(self, ...)
				if IsValid(self) then
					if self.OldOnDrop then
						DisableWeaponSpeed(self)

						self.OldOnDrop = nil
					end

					self:OnDrop()
				end
			end

			net.Start("ShootingSpeed")
			net.WriteBool(true)
			net.WriteEntity(wep)
			net.WriteFloat(wep.Primary.Delay)
			net.WriteFloat(wep.OldDelay)
			net.Send(wep.Owner)
		end
	end

	local function shootingModifier(ply, old, new)
		if IsValid(ply) then
			if ply:HasEquipmentItem("item_ttt_shootingspeed") then
				ApplyWeaponSpeed(new)
			end

			if IsValid(old) then
				DisableWeaponSpeed(old)
			end
		end
	end
	hook.Add("PlayerSwitchWeapon", "ShootingModifySpeed", shootingModifier)
else
	net.Receive("ShootingSpeed", function()
		local apply = net.ReadBool()
		local wep = net.ReadEntity()

		wep.Primary.Delay = net.ReadFloat()

		if apply then
			wep.OldOnDrop = wep.OnDrop

			wep.OnDrop = function(self, ...)
				if IsValid(self) then
					self.Primary.Delay = net.ReadFloat()
					self.OnDrop = self.OldOnDrop

					self:OnDrop()
				end
			end
		else
			wep.OnDrop = wep.OldOnDrop
		end
	end)
end
