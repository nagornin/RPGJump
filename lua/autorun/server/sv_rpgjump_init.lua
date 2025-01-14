CreateConVar("rpgjump_blast_multiplier", 2.5, FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Blast multiplier."
	.. " The higher this is, the more powerful the explosion blast will be.")

CreateConVar("rpgjump_enable_guidance", 1, FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Enable/disable rocket guidance")

CreateConVar("rpgjump_rapid_fire", 1, FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Allows to rapid fire the rocket launcher, even with an active missile")

CreateConVar("rpgjump_infinite_ammo", 1, FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Enable/disable infinite ammo for RPG")

CreateConVar("rpgjump_damage_multiplier", 0.1, FCVAR_NOTIFY + FCVAR_ARCHIVE,
	"Explosion damage multiplier")

CreateClientConVar("rpgjump_enable_ringing", 0, true, true,
	"Enable/disable the ringing sound effect caused by an explosion")

hook.Add("EntityTakeDamage", "RPGJumpScaleExplosionDamage", function(ent, info)
	local owner = info:GetInflictor().RPGJumpOwner

	if owner then
		info:SetAttacker(owner)
	end

	if ent:IsPlayer() and info:IsExplosionDamage()
		and info:GetInflictor():GetClass() == "rpg_missile"
	then
		local force = info:GetDamageForce()

		force:Div(ent:GetPhysicsObject():GetMass()
			/ GetConVar("rpgjump_blast_multiplier"):GetFloat())

		info:ScaleDamage(GetConVar("rpgjump_damage_multiplier"):GetFloat())
		ent:SetVelocity(force)
	end
end)

hook.Add("OnEntityCreated", "RPGJumpRapidRPGFire", function(ent)
	if ent:GetClass() ~= "rpg_missile" then return end

	timer.Simple(0, function()
		if ent == NULL then return end

		local ply = ent:GetInternalVariable("m_hOwnerEntity")

		if not (ply and ply:IsPlayer()) then return end

		if not GetConVar("rpgjump_enable_guidance"):GetBool() then
			ent:SetOwner(NULL)
			ent.RPGJumpOwner = ply
			ent:SetCustomCollisionCheck(true)
			ent:CollisionRulesChanged()
		end

		if GetConVar("rpgjump_infinite_ammo"):GetBool() then
			ply:SetAmmo(ply:GetAmmoCount("rpg_round") + 1, "rpg_round")
		end

		if GetConVar("rpgjump_rapid_fire"):GetBool() then
			local ammo = ply:GetAmmoCount("rpg_round")
			ply:SetActiveWeapon(NULL)
			ply:StripWeapon("weapon_rpg")
			ply:SetSuppressPickupNotices(true)
			local weapon = ply:Give("weapon_rpg", true)
			ply:SetAmmo(ammo, "rpg_round")
			ply:SetSuppressPickupNotices(false)
			ply:SetActiveWeapon(weapon)
		end
	end)
end)

hook.Add("ShouldCollide", "RPGJumpDisableRocketCollisionWithOwner",
	function(ent1, ent2)
		local ply = ent1:IsPlayer() and ent1 or ent2:IsPlayer() and ent2

		if not ply then return true end

		local rocket = ply == ent1 and ent2 or ent1

		if not rocket:GetClass() == "rpg_missile" then return true end

		return ply ~= rocket.RPGJumpOwner
	end)

hook.Add("OnDamagedByExplosion", "RPGJumpDisableRinging", function(ply)
	if ply:GetInfoNum("rpgjump_enable_ringing", 0) == 0 then
		return true 
	end
end)
