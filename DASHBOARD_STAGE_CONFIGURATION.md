# Dashboard Stage Configuration Solution

This solution addresses Issue #17 by providing multiple ways to configure which stages represent "won" and "lost" leads for dashboard reporting.

## Problem
The dashboard revenue statistics were hardcoded to only count gains and losses for stages with codes 'won' and 'lost'. When users customized these stage names (e.g., Brazilian users using 'ganho' and 'perda'), the dashboard would show zero revenue.

## Solution Overview
We implemented a 3-tier fallback system that ensures the dashboard works regardless of configuration access:

### 1. Admin Configuration (Primary)
- **Path**: Admin > Configuration > Dashboard Settings > Reporting Settings
- **Fields**: 
  - Won Stage Codes: Comma-separated list (e.g., `ganho,fechado,sucesso`)
  - Lost Stage Codes: Comma-separated list (e.g., `perda,perdido,cancelado`)
- **Use Case**: System administrators with full access

### 2. Pipeline-Level Configuration (Secondary)
- **Path**: Settings > Pipelines > Edit Pipeline > Each Stage
- **Fields**: Checkboxes for "Won Stage" and "Lost Stage"
- **Use Case**: Multi-user environments where individual users manage pipelines
- **Database**: Added `is_won_stage` and `is_lost_stage` columns to `lead_pipeline_stages` table

### 3. Intelligent Detection (Fallback)
- **Automatic detection** based on common stage naming patterns
- **Won patterns**: won, ganho, fechado, sucesso, closed-won, victory, vendido, finalizado, completed, success
- **Lost patterns**: lost, perda, perdido, cancelado, closed-lost, failed, rejected, descartado, cancelled, failure
- **Partial matching**: Detects words like "ganho" in "ganho-final" or "perdido" in "lead-perdido"

## Implementation Details

### Files Modified:
1. `packages/Webkul/Admin/src/Helpers/Reporting/Lead.php` - Enhanced reporting logic
2. `packages/Webkul/Admin/src/Config/core_config.php` - Added configuration options
3. `packages/Webkul/Lead/src/Models/Stage.php` - Added boolean fields for stage types
4. `packages/Webkul/Admin/src/Resources/views/settings/pipelines/create.blade.php` - Added checkboxes
5. `packages/Webkul/Admin/src/Resources/views/settings/pipelines/edit.blade.php` - Added checkboxes
6. Translation files for EN and PT-BR

### Database Migration:
```sql
ALTER TABLE lead_pipeline_stages 
ADD COLUMN is_won_stage BOOLEAN DEFAULT FALSE,
ADD COLUMN is_lost_stage BOOLEAN DEFAULT FALSE;
```

### Logic Flow:
1. Try to get stage codes from admin configuration
2. If empty, try to get stage IDs from database flags (`is_won_stage`, `is_lost_stage`)
3. If none found, use intelligent pattern matching
4. If still none found, fallback to original defaults ('won', 'lost')

## Usage Examples

### For Brazilian Users:
```php
// Configuration approach
Won Stage Codes: ganho,fechado,sucesso
Lost Stage Codes: perda,perdido,cancelado

// Or use pipeline checkboxes to mark stages as won/lost
// Or rely on automatic detection for common Portuguese terms
```

### For Multi-language Environments:
```php
Won Stage Codes: won,ganho,fermé,cerrado
Lost Stage Codes: lost,perda,perdu,perdido
```

## Benefits
- **Backward Compatible**: Existing installations continue to work unchanged
- **Multi-user Support**: Each pipeline can have its own stage configuration
- **Automatic Detection**: Works out-of-the-box for common naming patterns
- **Multi-language**: Supports Portuguese, English, and other languages
- **Robust Fallbacks**: Always finds appropriate stages even with custom names

## Testing
To test the solution:
1. Create stages with custom codes like 'ganho' and 'perda'
2. Verify dashboard shows correct revenue statistics
3. Test all three configuration methods
4. Ensure fallback logic works when configurations are empty