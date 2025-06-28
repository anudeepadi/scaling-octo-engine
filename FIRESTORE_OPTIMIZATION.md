# Firestore Performance Optimization Guide

## Required Composite Indexes

To achieve instant message retrieval, create these composite indexes in your Firebase Console:

### 1. Messages Collection Index
**Collection:** `messages/{userId}/chat`

**Index Configuration:**
```
Fields:
- createdAt: Descending
- __name__: Descending

Query scope: Collection
```

### 2. Real-time Updates Index
**Collection:** `messages/{userId}/chat`

**Index Configuration:**
```
Fields:
- createdAt: Descending
- serverMessageId: Ascending

Query scope: Collection
```

## How to Create Indexes

1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Enter the collection path and fields as specified above
4. Click "Create"

## Additional Performance Tips

1. **Enable Firestore Offline Persistence** (already done in code)
   - Allows instant display of cached messages
   - Reduces network calls

2. **Use Compound Queries**
   - The indexes above optimize for `orderBy('createdAt', descending)`
   - This is the most common query pattern in the app

3. **Monitor Performance**
   - Check Firebase Console → Performance Monitoring
   - Look for slow queries and create indexes accordingly

4. **Connection Pooling**
   - The app now warms up connections on initialization
   - This reduces cold start latency

## Testing Performance

After creating indexes:
1. Clear app data/cache
2. Launch the app
3. Messages should appear instantly from cache
4. New messages should appear within 100-200ms

## Troubleshooting

If messages are still slow:
1. Check if indexes are "Building" or "Ready" in Firebase Console
2. Verify network connection quality
3. Check Firebase Status page for any service issues
4. Review app logs for any errors

Remember: Indexes can take 5-10 minutes to build depending on data size.
