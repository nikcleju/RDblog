-- Lua filter to update BibTeX comments based on Quarto source

-- Function to read the content of a file
local function read_file(filename)
  local file = io.open(filename, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content
end

-- Function to write content to a file
local function write_file(filename, content)
  local file = io.open(filename, "w")
  if not file then return nil end
  file:write(content)
  file:close()
end

-- Function to update the comments in a BibTeX entry
local function update_bib_entry(bib_content, key, new_comment)
  -- Find the entry with the specified citation key
  local pattern = "@%w+{" .. key .. ",(.-)%b{}"
  local entry = bib_content:match(pattern)

  if not entry then
    print("Entry with key '" .. key .. "' not found in BibTeX file.")
    return bib_content
  end

  -- Check if the comment or note field exists and update it
  local updated_entry = entry:gsub("(comment = {.-})", "comment = {" .. new_comment .. "}")
      :gsub("(note = {.-})", "note = {" .. new_comment .. "}")

  -- Replace the old entry with the updated one
  bib_content = bib_content:gsub(pattern, updated_entry)

  return bib_content
end

function Pandoc(doc)
  -- Get the BibTeX file path from the command-line argument
  -- local bib_file = PANDOC_STATE.args[1]
  local bib_file = PANDOC_STATE.input_files[3]
  if not bib_file then
    print("No BibTeX file specified.")
    return
  end

  -- Load the existing BibTeX file
  local bib_content = read_file(bib_file)
  if not bib_content then
    print("Error reading BibTeX file: " .. bib_file)
    return
  end

  -- Variables to store parsed data
  local citation_key = ""
  local new_comment = ""

  -- Process the blocks in the document to extract key and comments
  for i, block in ipairs(doc.blocks) do
    if block.t == "Table" then
      -- The first row should contain the entry type and key (e.g., Article(Singh2022))
      local first_row = block.rows[1].cells[1].contents
      local first_row_text = pandoc.utils.stringify(first_row[1])

      -- Extract the entry type and key from the first line, e.g., Article(Singh2022)
      local entry_type, citation_key = first_row_text:match("^(%w+)%((.-)%)")
    end

    if block.t == "BulletList" then
      -- Process bullet points as new comments
      for _, item in pairs(block.content) do
        new_comment = new_comment .. pandoc.utils.stringify(item) .. "\n"
      end
    end
  end

  -- Update the BibTeX entry with the new comment
  if citation_key ~= "" then
    bib_content = update_bib_entry(bib_content, citation_key, new_comment)
  end

  -- Write the updated content back to the BibTeX file
  write_file(bib_file, bib_content)
end
