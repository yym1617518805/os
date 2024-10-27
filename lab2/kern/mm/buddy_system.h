#ifndef __KERN_MM_BUDDY_SYS_PMM_H__
#define __KERN_MM_BUDDY_SYS_PMM_H__

#include <pmm.h>
#define MAX_ORDER 20

extern const struct pmm_manager buddy_pmm_manager;

typedef struct {
    uint32_t order;                            // 伙伴二叉树的层数
    list_entry_t free_array[MAX_ORDER + 1];    // 空闲链表数组，每个数组元素都一个free_list头
    uint32_t nr_free;                          // 空闲页数量管理
} free_buddy_t;

#endif /* ! __KERN_MM_BUDDY_PMM_H__ */