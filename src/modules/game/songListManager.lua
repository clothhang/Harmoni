local SongListManager = {}

function SongListManager.getSongList(path)
    path = path or "Music/"

    if not love.filesystem.getInfo(path, "directory") then
        return {}
    end

    local songList = {}

    for _, item in ipairs(love.filesystem.getDirectoryItems(path)) do
        local itemPath = path .. item

        if love.filesystem.getInfo(itemPath, "directory") then
            local files = love.filesystem.getDirectoryItems(itemPath)

            for _, file in ipairs(files) do
                if getFileExtension(file) == "harmc" then
                    table.insert(songList, item)
                    break
                end
            end
        end
    end

    return songList
end

function SongListManager.getDifficultyList(path)
    local items = love.filesystem.getDirectoryItems(path)
    local list = {}
    for _, item in ipairs(items) do
        if getFileExtension(item) == "harmc" then
            table.insert(list, item)
        end
    end

    return list
end


return SongListManager