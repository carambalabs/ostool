import Commander

Group {
    $0.group("labels") { (labelsGroup) in
        labelsGroup.command("create", 
                            Argument<String>("org/repository", description: "e.g. ( carambalabs/ostool )"),
                            description: "create the default labels on the given repository") { (repository) in
            createLabels(repository: repository)
        }
    }
}.run()
