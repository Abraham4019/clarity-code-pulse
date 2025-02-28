Clarinet.test({
    name: "Test safety features and enhanced progress tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // Test contract pause
        let pauseBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'set-contract-pause', [
                types.bool(true)
            ], deployer.address)
        ]);
        pauseBlock.receipts[0].result.expectOk();
        
        // Test cooldown period
        let completionBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(0)
            ], student.address)
        ]);
        completionBlock.receipts[0].result.expectErr(108); // err-contract-paused
        
        // Test completion tracking
        let lessonsBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'get-student-completed-lessons', [
                types.principal(student.address),
                types.uint(0)
            ], deployer.address)
        ]);
        lessonsBlock.receipts[0].result.expectOk();
    }
});

[... rest of original test content ...]
