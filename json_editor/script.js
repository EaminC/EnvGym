class JSONTreeEditor {
  constructor() {
    this.data = [];
    this.selectedNode = null;
    this.nextId = 1;
    this.draggedNode = null;
    this.dragTarget = null;
    this.dragPreview = null;
    this.operationHistory = [];
    this.init();
  }

  init() {
    this.bindEvents();
    this.loadSampleData();
    this.render();
  }

  bindEvents() {
    // File operations
    document
      .getElementById("newFile")
      .addEventListener("click", () => this.newFile());
    document
      .getElementById("openFile")
      .addEventListener("click", () => this.openFile());
    document
      .getElementById("saveFile")
      .addEventListener("click", () => this.saveFile());
    document
      .getElementById("fileInput")
      .addEventListener("change", (e) => this.handleFileSelect(e));
    document
      .getElementById("copyJson")
      .addEventListener("click", () => this.copyJSON());

    // Add root node
    document
      .getElementById("addRoot")
      .addEventListener("click", () => this.addRootNode());

    // Undo button
    document
      .getElementById("undoMove")
      .addEventListener("click", () => this.undoLastMove());

    // Modal
    document
      .getElementById("modalCancel")
      .addEventListener("click", () => this.closeModal());
    document
      .getElementById("modalConfirm")
      .addEventListener("click", () => this.confirmModal());
    document
      .querySelector(".close")
      .addEventListener("click", () => this.closeModal());
    document.getElementById("modal").addEventListener("click", (e) => {
      if (e.target.id === "modal") this.closeModal();
    });

    // Keyboard shortcuts
    document.addEventListener("keydown", (e) => {
      if (e.ctrlKey || e.metaKey) {
        switch (e.key) {
          case "s":
            e.preventDefault();
            this.saveFile();
            break;
          case "o":
            e.preventDefault();
            this.openFile();
            break;
          case "n":
            e.preventDefault();
            this.newFile();
            break;
          case "z":
            e.preventDefault();
            this.undoLastMove();
            break;
        }
      }
    });

    // Global drag and drop events
    document.addEventListener("dragover", (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = "move";
    });

    document.addEventListener("drop", (e) => {
      e.preventDefault();
      if (this.draggedNode && this.dragTarget) {
        this.moveNode(this.draggedNode, this.dragTarget);
      }
      this.clearDragState();
    });

    // Mouse move for drag preview
    document.addEventListener("mousemove", (e) => {
      if (this.draggedNode) {
        this.updateDragPreview(e);
      }
    });
  }

  loadSampleData() {
    this.data = [
      {
        id: 1,
        task: "Project Development",
        weight: 100,
        type: "Development",
        expanded: true,
        children: [
          {
            id: 2,
            task: "Frontend Development",
            weight: 60,
            type: "Development",
            expanded: true,
            children: [
              {
                id: 3,
                task: "User Interface Design",
                weight: 30,
                type: "Design",
                expanded: false,
                children: [],
              },
              {
                id: 4,
                task: "Feature Implementation",
                weight: 30,
                type: "Development",
                expanded: false,
                children: [],
              },
            ],
          },
          {
            id: 5,
            task: "Backend Development",
            weight: 40,
            type: "Development",
            expanded: false,
            children: [
              {
                id: 6,
                task: "API Design",
                weight: 20,
                type: "Development",
                expanded: false,
                children: [],
              },
              {
                id: 7,
                task: "Database Design",
                weight: 20,
                type: "Development",
                expanded: false,
                children: [],
              },
            ],
          },
        ],
      },
    ];
    this.nextId = 8;
  }

  render() {
    this.renderTree();
    this.renderJSON();
    this.updateUndoButton();
  }

  renderTree() {
    const treeContainer = document.getElementById("jsonTree");
    treeContainer.innerHTML = "";

    if (this.data.length === 0) {
      treeContainer.innerHTML = `
                <div class="drop-zone">
                    <i class="fas fa-plus"></i>
                    <p>Click "Add Root" to start creating your task tree</p>
                </div>
            `;
      return;
    }

    this.data.forEach((node) => {
      treeContainer.appendChild(this.createTreeNode(node));
    });
  }

  createTreeNode(node) {
    const treeNode = document.createElement("div");
    treeNode.className = "tree-node";
    treeNode.dataset.id = node.id;

    const nodeContent = document.createElement("div");
    nodeContent.className = "node-content";
    nodeContent.draggable = true;

    // Drag events
    nodeContent.addEventListener("dragstart", (e) =>
      this.handleDragStart(e, node)
    );
    nodeContent.addEventListener("dragend", (e) => this.handleDragEnd(e));
    nodeContent.addEventListener("dragover", (e) =>
      this.handleDragOver(e, node)
    );
    nodeContent.addEventListener("drop", (e) => this.handleDrop(e, node));
    nodeContent.addEventListener("dragenter", (e) =>
      this.handleDragEnter(e, node)
    );
    nodeContent.addEventListener("dragleave", (e) => this.handleDragLeave(e));

    // Click events
    nodeContent.addEventListener("click", (e) => {
      if (
        !e.target.closest(".node-action") &&
        !e.target.closest(".expand-toggle")
      ) {
        this.selectNode(node);
      }
    });

    const hasChildren = node.children && node.children.length > 0;
    const isExpanded = node.expanded !== false; // Default to expanded

    nodeContent.innerHTML = `
            <div class="node-header">
                <div class="node-title">
                    ${
                      hasChildren
                        ? `<span class="expand-toggle ${
                            isExpanded ? "expanded" : ""
                          }" onclick="jsonEditor.toggleExpand(${node.id})">
                        <i class="fas fa-chevron-${
                          isExpanded ? "down" : "right"
                        }"></i>
                    </span>`
                        : '<span class="expand-placeholder"></span>'
                    }
                    <span class="drag-handle"><i class="fas fa-grip-vertical"></i></span>
                    ${this.escapeHtml(node.task)}
                </div>
                <div class="node-actions">
                    <button class="node-action" title="Add Child Node" onclick="jsonEditor.addChild(${
                      node.id
                    })">
                        <i class="fas fa-plus"></i>
                    </button>
                    <button class="node-action" title="Edit Node" onclick="jsonEditor.editNode(${
                      node.id
                    })">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="node-action" title="Delete Node" onclick="jsonEditor.deleteNode(${
                      node.id
                    })">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
            <div class="node-info">
                <span><i class="fas fa-weight-hanging"></i> Weight: ${
                  node.weight
                }</span>
                <span><i class="fas fa-tag"></i> Type: ${node.type}</span>
                ${
                  hasChildren
                    ? `<span><i class="fas fa-sitemap"></i> Subtasks: ${node.children.length}</span>`
                    : ""
                }
            </div>
        `;

    treeNode.appendChild(nodeContent);

    if (hasChildren && isExpanded) {
      const childrenContainer = document.createElement("div");
      childrenContainer.className = "children-container";

      node.children.forEach((child) => {
        childrenContainer.appendChild(this.createTreeNode(child));
      });

      treeNode.appendChild(childrenContainer);
    }

    return treeNode;
  }

  toggleExpand(nodeId) {
    const node = this.findNode(nodeId, this.data);
    if (node) {
      node.expanded = !node.expanded;
      this.render();
    }
  }

  handleDragStart(e, node) {
    console.log("Drag start for node:", node.id, node.task);
    this.draggedNode = node;
    e.dataTransfer.effectAllowed = "move";
    e.dataTransfer.setData("text/html", node.id);
    e.target.classList.add("dragging");

    // Create drag preview
    this.createDragPreview(node);
  }

  handleDragEnd(e) {
    console.log("Drag end");
    e.target.classList.remove("dragging");
    this.clearDragState();
    this.removeDragPreview();
  }

  handleDragOver(e, node) {
    e.preventDefault();
    e.dataTransfer.dropEffect = "move";

    if (this.draggedNode && this.draggedNode.id !== node.id) {
      console.log("Drag over node:", node.id, node.task);
      this.dragTarget = node;
      e.currentTarget.classList.add("drag-over");
      
      // Auto-expand if node has children and is not expanded
      if (node.children && node.children.length > 0 && !node.expanded) {
        node.expanded = true;
        this.render();
      }
    }
  }

  handleDrop(e, targetNode) {
    e.preventDefault();
    console.log("Drop on node:", targetNode.id, targetNode.task);
    e.currentTarget.classList.remove("drag-over");

    if (this.draggedNode && this.draggedNode.id !== targetNode.id) {
      this.moveNode(this.draggedNode, targetNode);
    }
    this.clearDragState();
  }

  handleDragEnter(e, node) {
    if (this.draggedNode && this.draggedNode.id !== node.id) {
      console.log("Drag enter node:", node.id);
      e.currentTarget.classList.add("drag-over");
    }
  }

  handleDragLeave(e) {
    e.currentTarget.classList.remove("drag-over");
  }

  clearDragState() {
    this.draggedNode = null;
    this.dragTarget = null;
    document.querySelectorAll(".drag-over").forEach((el) => {
      el.classList.remove("drag-over");
    });
    this.removeDragPreview();
  }

  moveNode(sourceNode, targetNode) {
    // Save operation for undo
    const operation = {
      type: "move",
      sourceNode: { ...sourceNode },
      targetNode: { ...targetNode },
      sourceParent: this.findParentNode(sourceNode.id, this.data),
      sourceIndex: this.findNodeIndex(sourceNode.id, this.data),
    };

    // Remove source node from its current location
    this.removeNodeFromData(sourceNode.id, this.data);

    // Add source node as child of target node
    if (!targetNode.children) {
      targetNode.children = [];
    }
    targetNode.children.push(sourceNode);
    targetNode.expanded = true; // Auto-expand target when dropping

    // Add to history
    this.operationHistory.push(operation);

    this.render();
    this.showNotification("Node moved successfully", "success");
  }

  findParentNode(nodeId, nodes) {
    for (let node of nodes) {
      if (node.children) {
        for (let child of node.children) {
          if (child.id === nodeId) {
            return node;
          }
          const found = this.findParentNode(nodeId, child.children);
          if (found) return found;
        }
      }
    }
    return null;
  }

  findNodeIndex(nodeId, nodes) {
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].id === nodeId) {
        return i;
      }
      if (nodes[i].children) {
        const found = this.findNodeIndex(nodeId, nodes[i].children);
        if (found !== -1) return found;
      }
    }
    return -1;
  }

  undoLastMove() {
    if (this.operationHistory.length === 0) {
      this.showNotification("No operations to undo", "info");
      return;
    }

    const lastOperation = this.operationHistory.pop();

    if (lastOperation.type === "move") {
      // Remove from current location
      this.removeNodeFromData(lastOperation.sourceNode.id, this.data);

      // Restore to original location
      if (lastOperation.sourceParent) {
        if (!lastOperation.sourceParent.children) {
          lastOperation.sourceParent.children = [];
        }
        lastOperation.sourceParent.children.splice(
          lastOperation.sourceIndex,
          0,
          lastOperation.sourceNode
        );
      } else {
        // Was a root node
        this.data.splice(
          lastOperation.sourceIndex,
          0,
          lastOperation.sourceNode
        );
      }

      this.render();
      this.showNotification("Move undone", "success");
    }
  }

  updateUndoButton() {
    const undoButton = document.getElementById("undoMove");
    if (undoButton) {
      undoButton.disabled = this.operationHistory.length === 0;
      undoButton.style.opacity =
        this.operationHistory.length === 0 ? "0.5" : "1";
    }
  }

  removeNodeFromData(nodeId, nodes) {
    // Remove from root level
    const rootIndex = nodes.findIndex((node) => node.id === nodeId);
    if (rootIndex !== -1) {
      nodes.splice(rootIndex, 1);
      return true;
    }

    // Remove from children
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].children) {
        const childIndex = nodes[i].children.findIndex(
          (child) => child.id === nodeId
        );
        if (childIndex !== -1) {
          nodes[i].children.splice(childIndex, 1);
          return true;
        }
        if (this.removeNodeFromData(nodeId, nodes[i].children)) {
          return true;
        }
      }
    }
    return false;
  }

  selectNode(node) {
    // Remove previous selection
    document.querySelectorAll(".node-content.selected").forEach((el) => {
      el.classList.remove("selected");
    });

    // Add new selection
    const nodeElement = document.querySelector(
      `[data-id="${node.id}"] .node-content`
    );
    if (nodeElement) {
      nodeElement.classList.add("selected");
    }

    this.selectedNode = node;
    this.renderEditor();
  }

  renderEditor() {
    const editorContent = document.getElementById("editorContent");
    const nodeInfo = document.getElementById("nodeInfo");

    if (!this.selectedNode) {
      editorContent.innerHTML = `
                <div class="placeholder">
                    <i class="fas fa-mouse-pointer"></i>
                    <p>Click on a node in the tree structure to edit its content</p>
                </div>
            `;
      nodeInfo.innerHTML = "<span>Please select a node to edit</span>";
      return;
    }

    nodeInfo.innerHTML = `
            <span><i class="fas fa-id-badge"></i> ID: ${
              this.selectedNode.id
            }</span>
            <span><i class="fas fa-level-up-alt"></i> Level: ${this.getNodeLevel(
              this.selectedNode
            )}</span>
        `;

    editorContent.innerHTML = `
            <form id="editForm">
                <div class="form-group">
                    <label for="editTask">Task Name:</label>
                    <input type="text" id="editTask" value="${this.escapeHtml(
                      this.selectedNode.task
                    )}" required>
                </div>
                <div class="form-group">
                    <label for="editWeight">Weight (0-100):</label>
                    <input type="number" id="editWeight" min="0" max="100" value="${
                      this.selectedNode.weight
                    }">
                </div>
                <div class="form-group">
                    <label for="editType">Type:</label>
                    <select id="editType">
                        <option value="Development" ${
                          this.selectedNode.type === "Development"
                            ? "selected"
                            : ""
                        }>Development</option>
                        <option value="Testing" ${
                          this.selectedNode.type === "Testing" ? "selected" : ""
                        }>Testing</option>
                        <option value="Design" ${
                          this.selectedNode.type === "Design" ? "selected" : ""
                        }>Design</option>
                        <option value="Documentation" ${
                          this.selectedNode.type === "Documentation"
                            ? "selected"
                            : ""
                        }>Documentation</option>
                        <option value="Other" ${
                          this.selectedNode.type === "Other" ? "selected" : ""
                        }>Other</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Actions:</label>
                    <div style="display: flex; gap: 10px;">
                        <button type="button" class="btn btn-primary" onclick="jsonEditor.saveNodeChanges()">
                            <i class="fas fa-save"></i> Save Changes
                        </button>
                        <button type="button" class="btn btn-secondary" onclick="jsonEditor.cancelEdit()">
                            <i class="fas fa-times"></i> Cancel
                        </button>
                    </div>
                </div>
            </form>
        `;
  }

  getNodeLevel(node) {
    let level = 1;
    let current = node;

    // Find parent node
    const findParent = (targetId, nodes) => {
      for (let node of nodes) {
        if (node.children) {
          for (let child of node.children) {
            if (child.id === targetId) {
              return node;
            }
            const found = findParent(targetId, child.children);
            if (found) return found;
          }
        }
      }
      return null;
    };

    while (findParent(current.id, this.data)) {
      level++;
      current = findParent(current.id, this.data);
    }

    return level;
  }

  addRootNode() {
    this.showModal(
      "Add Root Node",
      {
        task: "",
        weight: 50,
        type: "Development",
      },
      (data) => {
        const newNode = {
          id: this.nextId++,
          task: data.task,
          weight: parseInt(data.weight),
          type: data.type,
          expanded: true,
          children: [],
        };
        this.data.push(newNode);
        this.render();
      }
    );
  }

  addChild(parentId) {
    const parentNode = this.findNode(parentId, this.data);
    if (!parentNode) return;

    this.showModal(
      "Add Child Node",
      {
        task: "",
        weight: 50,
        type: "Development",
      },
      (data) => {
        const newNode = {
          id: this.nextId++,
          task: data.task,
          weight: parseInt(data.weight),
          type: data.type,
          expanded: false,
          children: [],
        };
        parentNode.children.push(newNode);
        parentNode.expanded = true; // Auto-expand parent when adding child
        this.render();
      }
    );
  }

  editNode(nodeId) {
    const node = this.findNode(nodeId, this.data);
    if (!node) return;

    this.showModal(
      "Edit Node",
      {
        task: node.task,
        weight: node.weight,
        type: node.type,
      },
      (data) => {
        node.task = data.task;
        node.weight = parseInt(data.weight);
        node.type = data.type;
        this.render();
        if (this.selectedNode && this.selectedNode.id === nodeId) {
          this.renderEditor();
        }
      }
    );
  }

  deleteNode(nodeId) {
    // Check if this is the last root node
    const rootIndex = this.data.findIndex((node) => node.id === nodeId);
    if (rootIndex !== -1 && this.data.length === 1) {
      this.showNotification("Cannot delete the last root node", "error");
      return;
    }

    if (
      !confirm(
        "Are you sure you want to delete this node? This will also delete all child nodes."
      )
    ) {
      return;
    }

    // Delete from root array
    if (rootIndex !== -1) {
      this.data.splice(rootIndex, 1);
    } else {
      // Delete from children
      this.removeNodeFromChildren(nodeId, this.data);
    }

    if (this.selectedNode && this.selectedNode.id === nodeId) {
      this.selectedNode = null;
    }

    this.render();
    this.showNotification("Node deleted successfully", "success");
  }

  removeNodeFromChildren(nodeId, nodes) {
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].children) {
        const childIndex = nodes[i].children.findIndex(
          (child) => child.id === nodeId
        );
        if (childIndex !== -1) {
          nodes[i].children.splice(childIndex, 1);
          return true;
        }
        if (this.removeNodeFromChildren(nodeId, nodes[i].children)) {
          return true;
        }
      }
    }
    return false;
  }

  saveNodeChanges() {
    if (!this.selectedNode) return;

    const taskInput = document.getElementById("editTask");
    const weightInput = document.getElementById("editWeight");
    const typeInput = document.getElementById("editType");

    if (!taskInput.value.trim()) {
      alert("Task name cannot be empty");
      return;
    }

    this.selectedNode.task = taskInput.value.trim();
    this.selectedNode.weight = parseInt(weightInput.value);
    this.selectedNode.type = typeInput.value;

    this.render();
    this.showNotification("Node saved successfully", "success");
  }

  cancelEdit() {
    this.renderEditor();
  }

  findNode(nodeId, nodes) {
    for (let node of nodes) {
      if (node.id === nodeId) {
        return node;
      }
      if (node.children) {
        const found = this.findNode(nodeId, node.children);
        if (found) return found;
      }
    }
    return null;
  }

  showModal(title, data, callback) {
    const modal = document.getElementById("modal");
    const modalTitle = document.getElementById("modalTitle");
    const taskName = document.getElementById("taskName");
    const taskWeight = document.getElementById("taskWeight");
    const taskType = document.getElementById("taskType");

    modalTitle.textContent = title;
    taskName.value = data.task;
    taskWeight.value = data.weight;
    taskType.value = data.type;

    modal.style.display = "block";
    taskName.focus();

    this.modalCallback = callback;
  }

  closeModal() {
    document.getElementById("modal").style.display = "none";
    this.modalCallback = null;
  }

  confirmModal() {
    const taskName = document.getElementById("taskName").value.trim();
    const taskWeight = document.getElementById("taskWeight").value;
    const taskType = document.getElementById("taskType").value;

    if (!taskName) {
      alert("Task name cannot be empty");
      return;
    }

    if (this.modalCallback) {
      this.modalCallback({
        task: taskName,
        weight: taskWeight,
        type: taskType,
      });
    }

    this.closeModal();
  }

  renderJSON() {
    const jsonOutput = document.getElementById("jsonOutput");
    // Remove expanded property from JSON output
    const cleanData = this.removeExpandedProperty(
      JSON.parse(JSON.stringify(this.data))
    );
    jsonOutput.textContent = JSON.stringify(cleanData, null, 2);
  }

  removeExpandedProperty(nodes) {
    nodes.forEach((node) => {
      delete node.expanded;
      if (node.children && node.children.length > 0) {
        this.removeExpandedProperty(node.children);
      }
    });
    return nodes;
  }

  newFile() {
    if (
      this.data.length > 0 &&
      !confirm(
        "Are you sure you want to create a new file? Current data will be lost."
      )
    ) {
      return;
    }
    this.data = [];
    this.selectedNode = null;
    this.nextId = 1;
    this.operationHistory = [];
    this.render();
    this.showNotification("New file created", "info");
  }

  openFile() {
    document.getElementById("fileInput").click();
  }

  handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const data = JSON.parse(e.target.result);
        // Add expanded property to existing nodes
        this.addExpandedProperty(data);
        this.data = data;
        this.nextId = this.getMaxId() + 1;
        this.selectedNode = null;
        this.operationHistory = [];
        this.render();
        this.showNotification("File loaded successfully", "success");
      } catch (error) {
        alert("Invalid file format. Please select a valid JSON file.");
      }
    };
    reader.readAsText(file);
  }

  addExpandedProperty(nodes) {
    nodes.forEach((node) => {
      if (node.expanded === undefined) {
        node.expanded = true; // Default to expanded
      }
      if (node.children && node.children.length > 0) {
        this.addExpandedProperty(node.children);
      }
    });
  }

  saveFile() {
    const cleanData = this.removeExpandedProperty(
      JSON.parse(JSON.stringify(this.data))
    );
    const dataStr = JSON.stringify(cleanData, null, 2);
    const dataBlob = new Blob([dataStr], { type: "application/json" });
    const url = URL.createObjectURL(dataBlob);

    const link = document.createElement("a");
    link.href = url;
    link.download = "task-tree.json";
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);

    this.showNotification("File saved successfully", "success");
  }

  copyJSON() {
    const jsonOutput = document.getElementById("jsonOutput");
    navigator.clipboard
      .writeText(jsonOutput.textContent)
      .then(() => {
        this.showNotification("JSON copied to clipboard", "success");
      })
      .catch(() => {
        // Fallback
        const textArea = document.createElement("textarea");
        textArea.value = jsonOutput.textContent;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand("copy");
        document.body.removeChild(textArea);
        this.showNotification("JSON copied to clipboard", "success");
      });
  }

  getMaxId() {
    let maxId = 0;
    const traverse = (nodes) => {
      for (let node of nodes) {
        if (node.id > maxId) maxId = node.id;
        if (node.children) traverse(node.children);
      }
    };
    traverse(this.data);
    return maxId;
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  showNotification(message, type = "info") {
    // Create notification element
    const notification = document.createElement("div");
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
            <i class="fas fa-${
              type === "success"
                ? "check-circle"
                : type === "error"
                ? "exclamation-circle"
                : "info-circle"
            }"></i>
            <span>${message}</span>
        `;

    // Add styles
    notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${
              type === "success"
                ? "#48bb78"
                : type === "error"
                ? "#f56565"
                : "#4299e1"
            };
            color: white;
            padding: 12px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            z-index: 10000;
            display: flex;
            align-items: center;
            gap: 10px;
            font-size: 14px;
            transform: translateX(100%);
            transition: transform 0.3s ease;
        `;

    document.body.appendChild(notification);

    // Show animation
    setTimeout(() => {
      notification.style.transform = "translateX(0)";
    }, 100);

    // Auto hide
    setTimeout(() => {
      notification.style.transform = "translateX(100%)";
      setTimeout(() => {
        document.body.removeChild(notification);
      }, 300);
    }, 3000);
  }

  // 拖拽预览相关方法
  createDragPreview(node) {
    this.removeDragPreview();

    this.dragPreview = document.createElement("div");
    this.dragPreview.className = "drag-preview";
    this.dragPreview.innerHTML = `
      <div class="drag-preview-content">
        <i class="fas fa-arrow-right"></i>
        <span>${node.task}</span>
        <small>Drop to move as child</small>
      </div>
    `;

    document.body.appendChild(this.dragPreview);
  }

  updateDragPreview(e) {
    if (this.dragPreview) {
      this.dragPreview.style.left = e.clientX + 10 + "px";
      this.dragPreview.style.top = e.clientY - 30 + "px";
    }
  }

  removeDragPreview() {
    if (this.dragPreview) {
      document.body.removeChild(this.dragPreview);
      this.dragPreview = null;
    }
  }
}

// Initialize editor
let jsonEditor;
document.addEventListener("DOMContentLoaded", () => {
  jsonEditor = new JSONTreeEditor();
});
