import Foundation
import TuistSupport
import TuistLoader
import TuistTemplate
import struct TemplateDescription.ParsedAttribute
import SPMUtility
import Basic

// swiftlint:disable:next type_body_length
class ScaffoldCommand: NSObject, Command {
    // MARK: - Attributes

    static let command = "scaffold"
    static let overview = "Generates new project based on template."
    private let listArgument: OptionArgument<Bool>
    private let pathArgument: OptionArgument<String>
    private let templateArgument: PositionalArgument<String>
    private let attributesArgument: OptionArgument<[String]>
    
    private let templateLoader: TemplateLoading
    private let templatesDirectoryLocator: TemplatesDirectoryLocating
    private let templateGenerator: TemplateGenerating

    // MARK: - Init

    public required convenience init(parser: ArgumentParser) {
        self.init(parser: parser,
                  templateLoader: TemplateLoader(),
                  templatesDirectoryLocator: TemplatesDirectoryLocator(),
                  templateGenerator: TemplateGenerator())
    }
    
    init(parser: ArgumentParser,
         templateLoader: TemplateLoading,
         templatesDirectoryLocator: TemplatesDirectoryLocating,
         templateGenerator: TemplateGenerating) {
        let subParser = parser.add(subparser: ScaffoldCommand.command, overview: ScaffoldCommand.overview)
        listArgument = subParser.add(option: "--list",
                                     shortName: "-l",
                                     kind: Bool.self,
                                     usage: "Lists available scaffold templates",
                                     completion: nil)
        templateArgument = subParser.add(positional: "template",
                                         kind: String.self,
                                         optional: true,
                                         usage: "Name of template you want to use",
                                         completion: nil)
        pathArgument = subParser.add(option: "--path",
                                     shortName: "-p",
                                     kind: String.self,
                                     usage: "The path to the folder where the project will be generated (Default: Current directory).",
                                     completion: .filename)
        attributesArgument = subParser.add(option: "--attributes",
                                           shortName: "-a",
                                           kind: [String].self,
                                           strategy: .remaining,
                                           usage: "Attributes for a given template",
                                           completion: nil)
        self.templateLoader = templateLoader
        self.templatesDirectoryLocator = templatesDirectoryLocator
        self.templateGenerator = templateGenerator
    }

    func run(with arguments: ArgumentParser.Result) throws {
        let path = try self.path(arguments: arguments)
        let directories = try templatesDirectoryLocator.templateDirectories()
        
        let shouldList = arguments.get(listArgument) ?? false
        if shouldList {
            try directories.forEach {
                let template = try templateLoader.loadTemplate(at: $0)
                Printer.shared.print("\($0.basename): \(template.description)")
            }
            return
        }
        
        guard let templateDirectory = directories.first(where: { $0.basename == arguments.get(templateArgument) }) else { fatalError() }
        try templateGenerator.generate(at: templateDirectory,
                                       to: path,
                                       attributes: arguments.get(attributesArgument) ?? [])
    }
    
    // MARK: - Helpers
    
    private func path(arguments: ArgumentParser.Result) -> AbsolutePath {
        if let path = arguments.get(pathArgument) {
            return AbsolutePath(path, relativeTo: FileHandler.shared.currentPath)
        } else {
            return FileHandler.shared.currentPath
        }
    }
}
