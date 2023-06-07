
type  
    Logger = object 
        debug: bool
        dest: File

# proc `Logger`*(debug: bool): Logger =
#     Logger(debug: debug, dest: stdout)

proc log*(logger: Logger, message: string) =
    logger.dest.write(message)

proc debug*(logger: Logger, message: string) =
    if logger.debug:
        logger.dest.write(message)