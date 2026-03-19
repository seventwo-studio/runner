# Changelog

## [1.3.0](https://github.com/seventwo-studio/devcontainers/compare/runner-v1.2.0...runner-v1.3.0) (2026-03-17)


### Features

* **runner:** align with GitHub-hosted runner environment ([6457858](https://github.com/seventwo-studio/devcontainers/commit/64578588a9cc95f3845dbcbf15bc42307ca4daf5))

## [1.2.0](https://github.com/seventwo-studio/devcontainers/compare/runner-v1.1.0...runner-v1.2.0) (2026-03-16)


### Features

* **runner:** update dependencies and add zstd for cache support ([cb644aa](https://github.com/seventwo-studio/devcontainers/commit/cb644aa057dceb48b4ad2a50b38775021e0ac44a))

## [1.1.0](https://github.com/seventwo-studio/devcontainers/compare/runner-v1.0.0...runner-v1.1.0) (2026-02-12)


### Features

* add Claude development tools to runner image ([19bc271](https://github.com/seventwo-studio/devcontainers/commit/19bc271071271a340269d8903a10b813052facb1))
* add claude-code feature and update devcontainer configurations ([7988b9f](https://github.com/seventwo-studio/devcontainers/commit/7988b9f525beb14163983882d264391a3898ca12))
* add comprehensive CI tests for runner image ([e00f22b](https://github.com/seventwo-studio/devcontainers/commit/e00f22bc577864cf5cfa9436ef7d968a1309039e))
* add comprehensive toolset to runner image ([1eb5b70](https://github.com/seventwo-studio/devcontainers/commit/1eb5b701f760a477a8735d45bd1489acf7fdaeac))
* Major repository cleanup and modernization ([a954483](https://github.com/seventwo-studio/devcontainers/commit/a9544837289230e1ec859faa0328026c9c187489))
* **runner:** add Bun runtime and fix Playwright version compatibility ([#23](https://github.com/seventwo-studio/devcontainers/issues/23)) ([62e0197](https://github.com/seventwo-studio/devcontainers/commit/62e0197bf7aac61a31280c6e90702fbae6282165))
* **runner:** add image processing libs, sharp/libvips support, and git-lfs ([9aa7cf5](https://github.com/seventwo-studio/devcontainers/commit/9aa7cf597baa25a24f03b34468675f4620e340b3))
* **runner:** add Java 17, Maestro CLI, and Expo E2E test ([89581e6](https://github.com/seventwo-studio/devcontainers/commit/89581e61b51485b2bc1ef3c74eaa88e3e4906ae1))


### Bug Fixes

* ensure mise directories have proper permissions for tests ([3748289](https://github.com/seventwo-studio/devcontainers/commit/3748289df3b6326ad62fe8ea80ebda71acd79c72))
* Fix Docker client version check in runner image test ([bc826e9](https://github.com/seventwo-studio/devcontainers/commit/bc826e98c38b00f0048b93e0a2cd8291f98bd1aa))
* Handle empty directories in runner image build ([9c60f64](https://github.com/seventwo-studio/devcontainers/commit/9c60f643fcc0782b7de087cbdb6205cc4bf44870))
* install claude-tools after runner user creation ([6efded2](https://github.com/seventwo-studio/devcontainers/commit/6efded223384493351571087353f0b9492a8ee26))
* install mise before running claude-tools script ([5a97422](https://github.com/seventwo-studio/devcontainers/commit/5a97422f6e440cf7852530d9ae3c2f0daced4dda))
* Make container tests more resilient to different build contexts ([4512d8a](https://github.com/seventwo-studio/devcontainers/commit/4512d8aee146a3f326e298e256e4524fedec36ce))
* Resolve all GitHub Actions workflow failures ([c9d1e03](https://github.com/seventwo-studio/devcontainers/commit/c9d1e03be8405e55b815b559b2bfff0bf43ef512))
* **runner:** add mise shims to PATH for direct tool access ([c53473b](https://github.com/seventwo-studio/devcontainers/commit/c53473b961a03390aaa2a78e51f766bb0a51e407))
* **runner:** set PATH environment variable for non-interactive shells ([f2f9e65](https://github.com/seventwo-studio/devcontainers/commit/f2f9e651fe563b8b1171bda4b7488bffa9255003))
* set HOME environment variable for runner user ([d24c178](https://github.com/seventwo-studio/devcontainers/commit/d24c178f8b2b50604519438e11aedd259fd9642c))
* set proper ownership for mise directories ([a849536](https://github.com/seventwo-studio/devcontainers/commit/a849536886a29dfd804eec63e9a2ba0e2826bb97))
* use netcat-openbsd instead of virtual netcat package ([edd6de5](https://github.com/seventwo-studio/devcontainers/commit/edd6de56ae3073f17090e4dbdab74d79bca5262e))
