const fs = require('fs')

const projectPath = process.argv[2]
const target = process.argv[3]
const version = process.argv[4]
const build = process.argv[5]

console.log(`Project path: ${projectPath}\nTarget: ${target}\nVersion: ${version}\nBuild: ${build}\n`)

const pbxprojPath = `${projectPath}/project.pbxproj`
const file = fs.readFileSync(pbxprojPath, 'utf8')
let content = file.toString('utf8')

const targetRegex = new RegExp(`[a-zA-Z0-9]{24}( \\/\\* ${target} \\*\\/ = {)(.+?)(name = "${target}";)(.+?)(};)`, 'gs')
const buildConfigurationListIdentifierRegex = /(buildConfigurationList = )[a-zA-Z0-9]{24}/

const targetSection = content.match(targetRegex)[0]
const buildConfigurationListIdentifier = targetSection.match(buildConfigurationListIdentifierRegex)[0].replace('buildConfigurationList = ', '')

const buildConfigurationRegex = new RegExp(`(\\t)(${buildConfigurationListIdentifier})(.+?)( = {)(.+?)(};)`, 'gs')
const buildConfiguration = content.match(buildConfigurationRegex)[0]

const debugRegex = /[a-zA-Z0-9]{24}( \/\* Debug \*\/,)/
const releaseRegex = /[a-zA-Z0-9]{24}( \/\* Release \*\/,)/

const debugBuildConfigurationIdentifier = buildConfiguration.match(debugRegex)[0].replace(' /* Debug */,', '')
const releaseBuildConfigurationIdentifier = buildConfiguration.match(releaseRegex)[0].replace(' /* Release */,', '')

const debugConfigurationRegex = new RegExp(`(${debugBuildConfigurationIdentifier})( \\/\\* Debug \\*\\/ = {)(.+?)(name = Debug;)(.+?)(};)`, 'gs')
const debugConfiguration = content.match(debugConfigurationRegex)[0]

const releaseConfigurationRegex = new RegExp(`(${releaseBuildConfigurationIdentifier})( \\/\\* Release \\*\\/ = {)(.+?)(name = Release;)(.+?)(};)`, 'gs')
const releaseConfiguration = content.match(releaseConfigurationRegex)[0]

const marketingVersionRegex = /(MARKETING_VERSION = )[0-9](.)[0-9](.)[0-9](;)/
const currentProjectVersionRegex = /(CURRENT_PROJECT_VERSION = )[0-9]+(;)/

let newDebugConfiguration = debugConfiguration
newDebugConfiguration = newDebugConfiguration.replace(marketingVersionRegex, `MARKETING_VERSION = ${version};`)
newDebugConfiguration = newDebugConfiguration.replace(currentProjectVersionRegex, `CURRENT_PROJECT_VERSION = ${build};`)

let newReleaseConfiguration = releaseConfiguration
newReleaseConfiguration = newReleaseConfiguration.replace(marketingVersionRegex, `MARKETING_VERSION = ${version};`)
newReleaseConfiguration = newReleaseConfiguration.replace(currentProjectVersionRegex, `CURRENT_PROJECT_VERSION = ${build};`)

content = content.replace(debugConfiguration, newDebugConfiguration)
content = content.replace(releaseConfiguration, newReleaseConfiguration)

fs.writeFileSync(pbxprojPath, content, { encoding: 'utf8'  })

console.log(`Version (${version}) and build number (${build}) was successfully written to the project file`)