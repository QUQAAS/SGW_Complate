local ac = require('ac')

local SkinApplier = {}
local originalSkin = ""

function SkinApplier.init()
    originalSkin = ac.getCarSkin(0) or "default"
end

function SkinApplier.applySkin(skinName)
    if skinName == "Orijinal" then
        SkinApplier.reset()
        return
    end

    if ac.setMaterialTexture then
        local mats = ac.getCarMaterials()
        if mats then
            for i, mat in ipairs(mats) do
                local name = mat.name:lower()
                if name:find('body') or name:find('paint') or name:find('skin') then
                    local texPath = 'cars/' .. ac.getCarModel(0) .. '/skins/' .. skinName .. '/' .. mat.texture
                    ac.setMaterialTexture(i, texPath)
                end
            end
            ac.log('[SGW SkinSwap] Applied skin: ' .. skinName)
        end
    else
        ac.log('[SGW SkinSwap] setMaterialTexture not available, needs slot swap')
    end
end

function SkinApplier.reset()
    if ac.setMaterialTexture then
        ac.log('[SGW SkinSwap] Reset to original skin')
    end
end

return SkinApplier