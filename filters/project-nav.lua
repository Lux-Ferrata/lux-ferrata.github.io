-- project-nav.lua: navigation through a project's posts.
--
-- For a post (posts/<slug>/index.qmd) with `project: "<project-slug>"` in its
-- frontmatter, appends a block linking to the project page and to the previous and
-- next posts of the same project. Posts are ordered by `date` (ISO, YYYY-MM-DD), then
-- title; drafts are skipped. Every other page passes through untouched.
--
-- It reads the other posts' frontmatter at render time, so CI's full render keeps
-- every post's links current when a post is added. Styled in styles.css (.project-nav).

local path = pandoc.path

local function read_file(p)
  local f = io.open(p, "r")
  if not f then return nil end
  local s = f:read("a")
  f:close()
  return s
end

-- The YAML frontmatter of a .qmd file, parsed by pandoc into a Meta table.
local function front_matter(p)
  local s = read_file(p)
  if not s then return nil end
  local yaml = s:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-")
  if not yaml then return nil end
  return pandoc.read("---\n" .. yaml .. "\n---\n", "markdown").meta
end

local function str(v)
  if v == nil then return nil end
  return pandoc.utils.stringify(v)
end

local function is_draft(meta)
  local d = meta.draft
  if d == nil then return false end
  if type(d) == "boolean" then return d end
  return str(d) == "true"
end

function Pandoc(doc)
  -- `project` is a reserved key in Quarto (project options), so it's dropped from
  -- doc.meta before filters run; read it from the file's own frontmatter instead.
  -- (Listings read the raw YAML, so `include: { project: ... }` sees it.)
  local input = quarto.doc.input_file
  local own = front_matter(input)
  local project = own and str(own.project)
  if not project or project == "" then return nil end

  local post_dir = path.directory(input)
  local posts_dir = path.directory(post_dir)
  if path.filename(posts_dir) ~= "posts" then return nil end
  local root = path.directory(posts_dir)
  local this_slug = path.filename(post_dir)

  -- every non-draft post in this project
  local posts = {}
  for _, slug in ipairs(pandoc.system.list_directory(posts_dir)) do
    local meta = front_matter(path.join({ posts_dir, slug, "index.qmd" }))
    if meta and str(meta.project) == project and not is_draft(meta) then
      table.insert(posts, {
        slug = slug,
        title = str(meta.title) or slug,
        date = str(meta.date) or "",
      })
    end
  end
  table.sort(posts, function(a, b)
    if a.date ~= b.date then return a.date < b.date end
    return a.title < b.title
  end)

  local index
  for i, p in ipairs(posts) do
    if p.slug == this_slug then index = i end
  end
  if not index then return nil end -- this post is a draft

  local project_meta = front_matter(path.join({ root, "projects", project, "index.qmd" }))
  local project_title = (project_meta and str(project_meta.title)) or project

  local function side(cls, label, p)
    if not p then return pandoc.Div({}, pandoc.Attr("", { cls })) end
    return pandoc.Div({
      pandoc.Plain({ pandoc.Span(label, pandoc.Attr("", { "project-nav-label" })) }),
      pandoc.Plain({ pandoc.Link(p.title, "../" .. p.slug .. "/index.qmd") }),
    }, pandoc.Attr("", { cls }))
  end

  local nav = pandoc.Div({
    pandoc.Para({
      pandoc.Str("Part of "),
      pandoc.Link(project_title, "../../projects/" .. project .. "/index.qmd"),
      pandoc.Str(" · post " .. index .. " of " .. #posts),
    }),
    pandoc.Div({
      side("project-nav-prev", "← Previous", posts[index - 1]),
      side("project-nav-next", "Next →", posts[index + 1]),
    }, pandoc.Attr("", { "project-nav-links" })),
  }, pandoc.Attr("", { "project-nav" }))

  doc.blocks:insert(nav)
  return doc
end
