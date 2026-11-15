report {
    uword checks
    uword failures
    uword first_failure
    sub check(bool result) {
        checks++
        if not result {
            failures++
            if first_failure==0
                first_failure=checks
        }
    }
    sub finish() {
        pokew($02f0,checks)
        pokew($02f2,failures)
        pokew($02f4,first_failure)
        @($02fe)=$a5
    }
}
