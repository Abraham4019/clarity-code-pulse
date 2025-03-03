Clarinet.test({
    name: "Test lesson completion security features",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const student = accounts.get('wallet_1')!;
        
        // Test lesson completion with non-existent lesson
        let completionBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(999)
            ], student.address)
        ]);
        completionBlock.receipts[0].result.expectErr(101); // err-not-found
        
        // Test duplicate lesson completion
        let duplicateBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(0)
            ], student.address),
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(0)
            ], student.address)
        ]);
        duplicateBlock.receipts[1].result.expectErr(109); // err-lesson-already-completed
        
        // Test progress overflow protection
        let overflowBlock = chain.mineBlock([
            Tx.contractCall('code-pulse', 'complete-lesson', [
                types.uint(0),
                types.uint(21)
            ], student.address)
        ]);
        overflowBlock.receipts[0].result.expectErr(105); // err-invalid-progress
    }
});

[... rest of original test content ...]
