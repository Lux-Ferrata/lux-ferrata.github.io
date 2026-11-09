-- alt-text.lua: warn about images that screen readers can't describe.
--
-- On every render (preview included) it prints a warning for:
--   * a post (posts/<slug>/index.qmd) with an `image:` but no `image-alt:`, which
--     leaves the listing card and link preview without alt text;
--   * an image in the body with no alt text (`![](x.png)` with neither a caption
--     nor `fig-alt`), including plots from code cells without `fig-alt`.
-- It only warns; it never fails the render or changes the page.

local function front_matter(p)
  local f = io.open(p, "r")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  local yaml = s:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-")
  if not yaml then return nil end
  return pandoc.read("---\n" .. yaml .. "\n---\n", "markdown").meta
end

local function blank(v)
  return v == nil or pandoc.utils.stringify(v):match("^%s*$") ~= nil
end

local input = quarto.doc.input_file
local where = pandoc.path.make_relative(input, quarto.project.directory or ".")

local function check_meta()
  local dir = pandoc.path.directory(input)
  if pandoc.path.filename(pandoc.path.directory(dir)) ~= "posts" then return end
  local meta = front_matter(input)
  if meta and not blank(meta.image) and blank(meta["image-alt"]) then
    quarto.log.warning(where .. ": `image:` has no `image-alt:` (listing card and link preview)")
  end
end

local function check_image(img)
  if #img.caption == 0 and blank(img.attributes["fig-alt"]) and blank(img.attributes["alt"]) then
    quarto.log.warning(where .. ": image without alt text: " .. img.src)
  end
end

return {
  { Pandoc = function() check_meta() end },
  { Image = check_image },
}
