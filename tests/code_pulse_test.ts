[... original test content ...]

Clarinet.test({
    name: "Test enhanced progress tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // Create course with 2 lessons
        let setupBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'create-course', [
                types.ascii("Python Basics"),
                types.uint(100)
            ], deployer.address),
            Tx.contractCall('code-pulse', 'add-lesson', [
                types.uint(0),
                types.ascii("Lesson 1"),
                types.uint(10)
            ], deployer.address),
            Tx.contractCall('code-pulse', 'add-lesson', [
                types.uint(0),
                types.ascii("Lesson 2"), 
                types.uint(10)
            ], deployer.address)
        ]);
        
        // Enroll and complete lessons
        let progressBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'enroll-in-course', [
                types.uint(0)
            ], student.address),
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(0)
            ], student.address),
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(1)
            ], student.address)
        ]);

        // Verify progress
        let progress = chain.callReadOnlyFn(
            'code-pulse',
            'get-student-progress',
            [types.principal(student.address), types.uint(0)],
            deployer.address
        );

        const enrollment = progress.result.expectOk().expectSome();
        assertEquals(enrollment['completed'], types.bool(true));
        assertTrue(enrollment['last-activity'] > types.uint(0));
    }
});
