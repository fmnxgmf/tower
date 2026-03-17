extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    await process_frame
    _run_suite("res://tests/test_project_bootstrap.gd")
    _run_suite("res://tests/test_core_logic.gd")
    if failures.is_empty():
        print("TESTS PASSED")
        quit(0)
        return
    printerr("TESTS FAILED:\n" + "\n".join(failures))
    quit(1)

func _run_suite(path: String) -> void:
    var suite_script = load(path)
    if suite_script == null:
        failures.append("%s: failed to load suite" % path)
        return
    if not suite_script.can_instantiate():
        failures.append("%s: script could not instantiate" % path)
        return
    var suite = suite_script.new()
    if suite == null:
        failures.append("%s: failed to instantiate suite" % path)
        return
    if not suite.has_method("run"):
        failures.append("%s: missing run() method" % path)
        return
    var result = suite.run()
    if result is Array:
        for entry in result:
            failures.append("%s: %s" % [path, str(entry)])
    elif result != null:
        failures.append("%s: unexpected test result %s" % [path, str(result)])
