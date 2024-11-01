# lab2

## 理解first-fit 连续物理内存分配算法
first-fit 连续物理内存分配算法作为物理内存分配一个很基础的方法，需要同学们理解它的实现过程。请大家仔细阅读实验手册的教程并结合kern/mm/default_pmm.c中的相关代码，认真分析default_init，default_init_memmap，default_alloc_pages， default_free_pages等相关函数，并描述程序在进行物理内存分配的过程以及各个函数的作用。 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
你的first fit算法是否有进一步的改进空间？
default_init初始化空闲链表 free_list 和空闲页计数器 nr_free。这是物理内存管理的初始化函数，确保所有数据结构都处于初始状态。
default_init_memmap初始化内存映射，将一段连续的物理页标记为空闲并添加到空闲链表中。遍历给定的页范围，将每页的标志和属性清零，然后设置页的属性为空闲页的数量，并将这些页链接到空闲链表中。更新空闲页计数器 nr_free。
default_alloc_pages分配指定数量的连续物理页。遍历空闲链表，找到第一个满足请求大小的空闲块。如果找到的空闲块过大，则拆分该块，将满足请求的部分返回给用户，剩余部分保留在空闲链表中。更新空闲页计数器 nr_free。
default_free_pages释放指定数量的连续物理页。将释放的页标记为空闲，并添加到空闲链表中。尝试与相邻的空闲块进行合并，以减少内存碎片。更新空闲页计数器 nr_free。
default_nr_free_pages返回当前空闲页的总数。
default_check检查内存管理的正确性，包括空闲链表的有效性和内存分配释放的逻辑。
first fit算法是找到第一个合适的，但不一定是最合适的，所以可以循环所有的内存，比较找出最合适的那个进行选择，即 Best-Fit 算法。

## 实现 Best-Fit 连续物理内存分配算法
### Best Fit 页面分配算法设计思路
初始化内存映射（best_fit_init_memmap）：

初始化给定页块的状态，将所有页框的标志和属性信息清空，并设置引用计数为0。
将页块的属性设置为其包含的页数，并将其添加到空闲页链表中，按顺序插入到合适的位置以保持链表的有序性。
页面分配（best_fit_alloc_pages）：

### 遍历空闲链表，查找满足请求的最小的空闲块。

使用 min_size 变量记录找到的最小符合要求的空闲块的大小。
如果找到合适的空闲块，则将其从链表中删除，并根据需要将其分割成两个部分（已分配和剩余空闲部分）。
更新空闲页的数量。
页面释放（best_fit_free_pages）：

### 释放指定的页块，并清空其标志和属性信息。
更新空闲页块的属性，将当前页块标记为已释放，并增加可用空闲页的数量。
在释放后，检查前后页块是否连续，如果是，则合并这些空闲页块，更新其属性并从链表中删除合并的块。

其实best_fit和first_fit几乎一模一样，就是在选取分配快的时候，遍历所有的块，找到最合适的哪一个（空间足够并且大小最小），这样进行分配，使得利用效率更高。

问题：你的 Best-Fit 算法是否有进一步的改进空间？
答案：Best-Fit 算法存在碎片化、查找效率低、预测和预分配待实现、缓存机制、并发性和线程安全等改进空间，可以考虑合并碎片、使用更高效的数据结构（例如AVL树）、大小类（Size Class）分配器等优化方案。

## buddy system（伙伴系统）分配算法
Buddy System算法把系统中的可用存储空间划分为存储块(Block)来进行管理, 每个存储块的大小必须是2的n次幂(Pow(2, n)), 即1, 2, 4, 8, 16, 32, 64, 128...
参考伙伴分配器的一个极简实现， 在ucore中实现buddy system分配算法，要求有比较充分的测试用例说明实现的正确性，需要有设计文档。
伙伴系统算法把内存分割成若干大小是2的幂次方的块进行管理。当需要分配内存时，算法会寻找满足请求的最小空闲块；释放内存时，算法会检查相邻的块是否为空闲，如果是，则进行合并。free_buddy_t：存储伙伴系统的核心数据，包括空闲链表数组、空闲页总数和最大阶数。struct Page：表示物理内存中的一页，包含页面的状态、属性和链表指针等。list_entry_t：双向链表节点，用于连接空闲内存块。
buddy_init：初始化伙伴系统，将所有空闲链表置为空。
buddy_memmap_init：根据给定的内存块初始化伙伴系统，将内存块分配到相应的阶数链表中。（不会全部分配，只会将页面数n向下取整到最接近的2的幂次方。）
buddy_split_block：拆分较大的内存块为较小的块，直到满足请求的大小。
buddy_alloc_pages：分配指定数量的内存页。首先计算所需内存页的阶数，然后查找对应的空闲链表。如果链表为空，则拆分更高阶的块。分配后，更新空闲页数和块的属性。
find_buddy：根据给定页面找到其伙伴块的地址。
buddy_free_pages：释放指定数量的内存页，并尝试与伙伴块合并。首先找到释放块对应的阶数，将其重新加入空闲链表。然后，查找伙伴块并尝试合并，直到无法合并或达到最大阶数。
buddy_free_pages_count：返回当前系统中的空闲页数。
display_buddy_structure：显示当前的空闲链表结构，便于调试和观察内存分配情况。
buddy_check：基本的测试函数，验证内存分配和释放是否正常工作。通过分配和释放不同大小的内存块，并显示空闲链表结构来观察内存分配情况。


## 硬件的可用物理内存范围的获取方法

如果 OS 无法提前知道当前硬件的可用物理内存范围，请问你有何办法让 OS 获取可用物理内存范围？

当操作系统（OS）无法提前知道当前硬件的可用物理内存范围时，可以通过Bootloader来获取这些信息。Bootloader是操作系统启动前运行的一段代码，在操作系统加载之前，Bootloader会执行一系列硬件初始化操作，包括内存初始化。这包括检测物理内存的大小和范围，为操作系统提供必要的内存信息。Bootloader还会设置内存映射，确保操作系统能够正确地访问物理内存。这包括建立中断向量表、设置内存保护模式等。在完成硬件初始化和内存映射设置后，Bootloader会加载操作系统内核，并将控制权交给操作系统。在这个过程中，Bootloader会将之前获取的内存信息传递给操作系统。

