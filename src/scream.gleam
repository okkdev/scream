import clip
import clip/arg
import clip/help
import clip/opt
import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import shellout
import simplifile
import temporary

type ScreamConfig {
  ScreamConfig(
    script: String,
    target: Result(String, Nil),
    runtime: Result(String, Nil),
    dependencies: Result(List(String), Nil),
  )
}

pub opaque type ScreamError {
  FileError(simplifile.FileError)
  GleamError
}

pub fn main() {
  let result =
    command()
    |> clip.help(help.simple("scream", "run gleam scripts"))
    |> clip.run(shellout.arguments())

  case result {
    Error(e) -> io.println_error(e) |> Ok
    Ok(config) -> config |> run
  }
}

fn command() {
  clip.command({
    use script <- clip.parameter
    use target <- clip.parameter
    use runtime <- clip.parameter
    use dependencies <- clip.parameter

    ScreamConfig(script:, target:, runtime:, dependencies:)
  })
  |> clip.arg(
    arg.new("script")
    |> arg.help("The Gleam script you want to run")
    |> arg.try_map(fn(script) {
      case string.ends_with(script, ".gleam") {
        True -> Ok(script)
        False -> Error("script should be a .gleam file")
      }
    }),
  )
  |> clip.opt(opt.new("target") |> opt.optional |> opt.help("Gleam target"))
  |> clip.opt(opt.new("runtime") |> opt.optional |> opt.help("Gleam runtime"))
  |> clip.opt(
    opt.new("dependencies")
    |> opt.short("d")
    |> opt.help("Comma separated extra Gleam dependencies")
    |> opt.map(string.split(_, on: ","))
    |> opt.optional,
  )
}

fn run(config: ScreamConfig) -> Result(Nil, ScreamError) {
  use temp_dir <-
    fn(x) {
      temporary.create(
        temporary.directory()
          |> temporary.with_prefix("scream"),
        x,
      )
      |> result.map_error(FileError(_))
    }

  let assert Ok(Nil) = setup(temp_dir, config.script)

  let opts =
    [
      config.target
        |> result.map(fn(t) { ["--target=" <> t] })
        |> result.unwrap([]),
      config.runtime
        |> result.map(fn(t) { ["--runtime=" <> t] })
        |> result.unwrap([]),
    ]
    |> list.concat

  // use _ <- result.try(install_deps(temp_dir, config.dependencies))
  case install_deps(temp_dir, config.dependencies) {
    Ok(_) -> {
      let _ =
        shellout.command(
          run: "gleam",
          with: ["run", ..opts],
          in: temp_dir,
          opt: [shellout.LetBeStderr, shellout.LetBeStdout],
        )
        |> result.replace(Nil)
        |> result.replace_error(GleamError)
      Nil
    }
    Error(_) -> Nil
  }
}

fn setup(path: String, filename: String) -> Result(Nil, ScreamError) {
  let name =
    string.split(filename, ".gleam")
    |> list.first
    |> result.unwrap("")

  let gleam_toml = "
name = \"" <> name <> "\"
version = \"1.0.0\"
[dependencies]
gleam_stdlib = \">= 0.34.0 and < 2.0.0\"
    "

  let src_dir = filepath.join(path, "src/")

  use _ <- result.try(
    simplifile.create_directory(src_dir)
    |> result.map_error(FileError(_)),
  )
  use _ <- result.try(
    simplifile.write(
      to: filepath.join(path, "gleam.toml"),
      contents: gleam_toml,
    )
    |> result.map_error(FileError(_)),
  )
  simplifile.copy_file(
    filepath.join(".", filename),
    filepath.join(src_dir, filename),
  )
  |> result.map_error(FileError(_))
}

fn install_deps(
  path: String,
  deps: Result(List(String), Nil),
) -> Result(Nil, ScreamError) {
  case deps {
    Ok([]) -> Ok(Nil)
    Ok(deps) ->
      deps
      |> list.map(fn(dep) {
        shellout.command(run: "gleam", with: ["add", dep], in: path, opt: [
          shellout.LetBeStderr,
          shellout.LetBeStdout,
        ])
      })
      |> result.all
      |> result.replace(Nil)
      |> result.replace_error(GleamError)
    Error(_) -> Ok(Nil)
  }
}
