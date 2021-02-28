ITEM.hud = Material("vgui/ttt/perks/hud_shootingspeed.png")
ITEM.EquipMenuData = {
	type = "item_passive",
	name = "shootingspeed",
	desc = "You shoot 30% faster!"
}
ITEM.material = "vgui/ttt/icon_shootingspeed"
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
		if not IsValid(wep) or not wep.m_shootingSpeed then return end

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
		wep.m_shootingSpeed = nil
	end

	local function ApplyWeaponSpeed(wep)
		if not IsValid(wep) or wep.m_shootingSpeed
		or wep.Kind ~= WEAPON_HEAVY and wep.Kind ~= WEAPON_PISTOL then return end

		wep.OldDelay = wep.Primary.Delay
		wep.Primary.Delay = math.Round(wep.Primary.Delay / 1.5, 3)
		wep.OldOnDrop = wep.OnDrop
		wep.m_shootingSpeed = true

		wep.OnDrop = function(self, ...)
			DisableWeaponSpeed(self)

			if IsValid(self) and isfunction(self.OnDrop) then
				self:OnDrop(...)
			end
		end

		net.Start("ShootingSpeed")
		net.WriteBool(true)
		net.WriteEntity(wep)
		net.WriteFloat(wep.Primary.Delay)
		net.WriteFloat(wep.OldDelay)
		net.Send(wep.Owner)
	end

	local function shootingModifier(ply, old, new)
		if not IsValid(ply) then return end

		if ply:HasEquipmentItem("item_ttt_shootingspeed") then
			ApplyWeaponSpeed(new)
		end

		if IsValid(old) then
			DisableWeaponSpeed(old)
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
			wep.m_shootingSpeed = true

			wep.OnDrop = function(self, ...)
				if not IsValid(self) then return end

				self.Primary.Delay = net.ReadFloat()
				self.OnDrop = self.OldOnDrop
				self.m_shootingSpeed = false

				if isfunction(self.OnDrop) then
					self:OnDrop(...)
				end
			end
		else
			wep.OnDrop = wep.OldOnDrop
			wep.m_shootingSpeed = nil
		end
	end)
end
