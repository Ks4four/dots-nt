#region [ Metadata & Architecture ]
#
# Jwno Configuration - Modal State Machine
#
# Author: Generated
#
# --- Architecture Overview ---
# 1. State Machine: Unlike standard Jwno configs that use a stack (push/pop), 
#    this config uses a flat state machine. Switching modes completely replaces 
#    the root keymap via `:set-keymap`.
#
# 2. IPC / Status: State (Current Mode, Depth, Viewport Status) is serialized 
#    to a JSON file on the Desktop after every relevant hook. This allows 
#    external widgets (Yasb) to render the UI reactively.
#
# 3. Input Philosophy:
#    - Left Hand (Keyboard): Selection & Navigation (hjkl, g, v, f).
#    - Right Hand (Knob/Arrows): Value Adjustment (Resize, Scroll, Alpha).
#
# --- Mode Definitions ---
# NORMAL : Navigation & Management
# INSERT : Layout splitting (Binary Space Partitioning style)
# RESIZE : Frame dimension adjustment
# SCROLL : Viewport panning within frames
# CARRY  : Moving windows between frames
# ALPHA  : Window transparency control
# GOTO   : UI Automation (UIA) interactions & filtering
# OUTER  : Top-level frame/monitor manipulation
#
#endregion

#region [ Imports ]
(import jwno/auto-layout)
(import jwno/indicator)
(import jwno/ui-hint)
(import jwno/util)
(import jwno/log)
(import jwno/scratch-pad)

(use jw32/_uiautomation)
#endregion

#region [ Global Context & Config ]

(log/info "===== JWNO CONFIG LOADED =====")

# Context Managers provided by Jwno runtime
(def key-man (in jwno/context :key-manager))
(def command-man (in jwno/context :command-manager))
(def window-man (in jwno/context :window-manager))
(def ui-man (in jwno/context :ui-manager))
(def hook-man (in jwno/context :hook-manager))

# UI Hint allowed keys (Home row + surrounding)
(def hint-key-list "asdfhjkl") 

# [IPC] Path for status JSON. External bars watch this file.
(def status-file "C:/Users/Ksfour/Desktop/jwno-status.json")

# Runtime State Variables
(var current-frame nil)
(var current-window nil)
(var active-mode-name "PASSTHROUGH")

#endregion

#region [ Status Logic & IPC ]

    #region [ Tree Traversal ]
    # Calculates the nesting depth of the current frame.
    # LOGIC: Traverses the frame tree upwards via `:parent`.
    #        Stops at the `:monitor` node to avoid counting internal root nodes.
    (defn calculate-depth [frame]
      (if (in frame :monitor)
        0 
        (do
          (var depth 1)
          (var f (in frame :parent))
          (while f
            (if (in f :monitor)
              (break)
              (do
                 (set depth (+ depth 1))
                 (set f (in f :parent)))))
          depth)))

    # Calculates sibling position indices.
    (defn calculate-position [item parent-key]
      (var pos 1)
      (var total 1)
      (when item
        (def parent (in item parent-key))
        (when parent
          (def siblings (in parent :children))
          (when siblings
            (set total (length siblings))
            (var i 0)
            (while (< i total)
              (when (= (in siblings i) item)
                (set pos (+ i 1))
                (break))
              (set i (+ i 1))))))
      {:position pos :total total})
    #endregion

    #region [ Serialization ]
    # Serializes the current Jwno state to JSON.
    # Triggered by hooks to ensure external UI is always in sync.
    (defn write-status-file []
      (var depth 0)
      (var win-pos 0)
      (var win-total 0)
      (var frame-pos 1)
      (var frame-total 1)
      (var viewport-active 0)
      
      (when current-frame
        # 1. Calculate Depth & Frame Position
        (set depth (calculate-depth current-frame))
        (def frame-info (calculate-position current-frame :parent))
        (set frame-pos (in frame-info :position))
        (set frame-total (in frame-info :total))
        
        # 2. Check Viewport Status (Unconstrained Mode)
        (when (in current-frame :parent)
          (def parent (in current-frame :parent))
          (when (in parent :viewport)
            (set viewport-active 1)))

        # 3. Calculate Window Position within Frame
        (def children (in current-frame :children))
        (when children
          (set win-total (length children))
          (when current-window
            (var i 0)
            (while (< i win-total)
              (when (= (in children i) current-window)
                (set win-pos (+ i 1))
                (break))
              (set i (+ i 1))))))
      
      # 4. Construct JSON Payload
      (def json (string
        "{"
        `"mode":"` active-mode-name `",`
        `"viewport":` viewport-active `,`
        `"timestamp":` (os/time) `,`
        `"depth":` depth `,`
        `"window":{"position":` win-pos `,"total":` win-total `},`
        `"frame":{"position":` frame-pos `,"total":` frame-total `}`
        "}"))
      
      # 5. Atomic Write
      (def f (file/open status-file :w))
      (when f
        (file/write f json)
        (file/close f)))

    (defn update-status [] (write-status-file))
    #endregion

#endregion

#region [ Layout Helpers ]

# Logic to auto-focus the new frame after a split operation
(defn move-window-after-split [frame]
  (def all-sub-frames (in frame :children))
  (def all-wins (in (first all-sub-frames) :children))
  (def move-to-frame (in all-sub-frames 1))
  (when (>= (length all-wins) 2)
    (:add-child move-to-frame (:get-current-window frame)))
  (:activate move-to-frame))

# Directional Insert Helpers (mapped to hjkl)
(defn insert-left [frame]
  (def sub-frames (in frame :children))
  (def left-frame (first sub-frames))
  (def right-frame (in sub-frames 1))
  (each win (in left-frame :children) (:add-child right-frame win))
  (:activate left-frame))

(defn insert-right [frame]
  (def sub-frames (in frame :children))
  (:activate (in sub-frames 1)))

(defn insert-above [frame]
  (def sub-frames (in frame :children))
  (def top-frame (first sub-frames))
  (def bottom-frame (in sub-frames 1))
  (each win (in top-frame :children) (:add-child bottom-frame win))
  (:activate top-frame))

(defn insert-below [frame]
  (def sub-frames (in frame :children))
  (:activate (in sub-frames 1)))

(defn activate-inserted-frame [frame]
  (:activate frame))

#endregion

#region [ Keymap Initialization ]

    #region [ Allocation ]
    # Pre-allocate keymaps to allow cyclic references in mode switching
    (def km-root   (:new-keymap key-man))
    (def km-normal (:new-keymap key-man))
    (def km-insert (:new-keymap key-man))
    (def km-resize (:new-keymap key-man))
    (def km-scroll (:new-keymap key-man))
    (def km-carry  (:new-keymap key-man))
    (def km-alpha  (:new-keymap key-man))
    (def km-goto   (:new-keymap key-man))
    (def km-outer  (:new-keymap key-man))
    #endregion

    #region [ State Transitions ]
    # Command: :set-mode
    # Implements the State Machine transition. Replaces the entire active keymap.
    (:add-command command-man :set-mode
      (fn [target-km name]
        (:set-keymap key-man target-km)
        (set active-mode-name name)
        # Visual feedback via built-in tooltip (optional)
        (:show-tooltip ui-man :mode (string "-- " name " --") nil nil 1000 :top-left)
        # Trigger IPC update
        (update-status)))

    # Command: :set-window-alpha
    # Helper for direct alpha setting
    (:add-command command-man :set-window-alpha
      (fn [alpha] (when current-window (:set-alpha current-window alpha))))

    # Command: :show-current-keymap
    # Shows help overlay
    (:add-command command-man :show-current-keymap
      (fn []
        (:show-tooltip ui-man :keymap active-mode-name nil nil 5000 :center)))
    #endregion

#endregion

#region [ Binding Abstractions ]

# Registry of all available modes.
# Format: "Trigger Key" -> [Keymap Object, Mode Name String]
# Note: "n" maps to NORMAL to allow universal exit to Normal mode.
(def modes {
  "i" [km-insert "INSERT"]
  "r" [km-resize "RESIZE"]
  "s" [km-scroll "SCROLL"]
  "c" [km-carry  "CARRY"]
  "a" [km-alpha  "ALPHA"]
  "g" [km-goto   "GOTO"]
  "o" [km-outer  "OUTER"]
  "n" [km-normal "NORMAL"]
})

# Mixin: Standard Navigation
# Applies HJKL (Frame move) and Ctrl+HJKL (Window cycle) to a keymap.
(defn bind-navigation [km]
  (:define-key km "h" [:adjacent-frame :left])
  (:define-key km "j" [:adjacent-frame :down])
  (:define-key km "k" [:adjacent-frame :up])
  (:define-key km "l" [:adjacent-frame :right])
  (:define-key km "Ctrl + h" [:enum-window-in-frame :prev])
  (:define-key km "Ctrl + k" [:enum-window-in-frame :prev])
  (:define-key km "Ctrl + l" [:enum-window-in-frame :next])
  (:define-key km "Ctrl + j" [:enum-window-in-frame :next]))

# Mixin: Universal Actions
# Applies common shortcuts (Close, Balance, Help, Hints) to a keymap.
# Also handles the Mode Switching logic via the `modes` registry.
(defn bind-common [km is-sub-mode]

  # ======================================================================================
  # [LOGIC: GLOBAL TOGGLE STATE]
  # 
  # Purpose: Completes the "Toggle" logic for the F23 key.
  # 1. ENTRY (Toggle ON): Defined in 'km-root' (at the bottom of this file), 
  #    F23 switches from Passthrough -> NORMAL.
  # 
  # 2. EXIT (Toggle OFF): Defined here. 
  #    F23 switches from Any Mode -> PASSTHROUGH (km-root).
  #
  # Why here? 
  # Since 'bind-common' is applied to ALL functional modes (Normal, Insert, Resize, etc.),
  # this ensures that pressing F23 acts as a universal "Exit Strategy". Whether you are 
  # deep in 'Resize' mode or just in 'Normal', F23 will instantly close the management 
  # state and return input control to the OS.
  # ======================================================================================
  (:define-key km "F23" [:set-mode km-root "PASSTHROUGH"])

  # --- Core Window Management ---
  (:define-key km "d" :close-window-or-frame)
  (:define-key km "x" :close-frame)
  (:define-key km "=" :balance-frames)
  (:define-key km "z" :toggle-window-management)
  (:define-key km "p" :toggle-parent-viewport)
  (:define-key km "q" :flatten-parent)          
  (:define-key km "u" :toggle-parent-direction) 
  
  # --- Global UI Interaction (Hinters) ---
  # v = Visit (Focus), f = Frame Selection
  (:define-key km "v"         [:ui-hint hint-key-list (ui-hint/uia-hinter :condition [:property UIA_IsKeyboardFocusablePropertyId true] :action :focus)])
  (:define-key km "f"         [:ui-hint hint-key-list (ui-hint/frame-hinter)]) 
  
  # Mouse Emulation via Hints
  (:define-key km "."         [:ui-hint hint-key-list]) # Left Click
  (:define-key km ","         [:ui-hint hint-key-list (ui-hint/uia-hinter :action :right-click)]) # Right Click
  (:define-key km "Shift + ." [:ui-hint hint-key-list (ui-hint/uia-hinter :action :double-click)])
  (:define-key km "Shift + ," [:ui-hint hint-key-list (ui-hint/uia-hinter :action :middle-click)])

  # --- Meta / Help ---
  (:define-key km "Shift + /" :show-current-keymap) 
  (:define-key km "/" :describe-key) 

  # --- Escape Strategy ---
  # SubMode -> Normal -> Passthrough
  (if is-sub-mode
    (:define-key km "Esc" [:set-mode km-normal "NORMAL"])
    (:define-key km "Esc" [:set-mode km-root "PASSTHROUGH"]))
  
  # --- Mode Switching Injection ---
  # Iterates through the `modes` dict and binds entry keys for every mode.
  (eachk key modes
    (def info (in modes key))
    (def target-km (get info 0))
    (def target-name (get info 1))
    (:define-key km key [:set-mode target-km target-name])))

# Apply abstractions
(def sub-modes [km-insert km-resize km-scroll km-carry km-alpha km-goto km-outer])
(each km sub-modes (bind-common km true))
(bind-common km-normal false)

#endregion

#region [ Mode Implementations ]

    #region [ GOTO ]
    # Advanced UI Automation filtering and drill-down
    (put km-goto :name "GOTO")
    (bind-navigation km-goto) 
    
    # Gradual Drill-down
    (:define-key km-goto "'" [:ui-hint hint-key-list (ui-hint/gradual-uia-hinter :show-highlights true)])

    # UIA Property Filters
    # 'b' = Buttons / Checkboxes
    (:define-key km-goto "b" [:ui-hint hint-key-list 
      (ui-hint/uia-hinter :condition [:or 
        [:property UIA_ControlTypePropertyId UIA_ButtonControlTypeId] 
        [:property UIA_ControlTypePropertyId UIA_CheckBoxControlTypeId]])])
    
    # 'e' = Editable fields
    (:define-key km-goto "e" [:ui-hint hint-key-list
      (ui-hint/uia-hinter :condition [:and
        [:or
          [:property UIA_ControlTypePropertyId UIA_EditControlTypeId]
          [:property UIA_ControlTypePropertyId UIA_ComboBoxControlTypeId]]
        [:property UIA_IsKeyboardFocusablePropertyId true]])])

    # '1' = List Items
    (:define-key km-goto "1" [:ui-hint hint-key-list
      (ui-hint/uia-hinter :condition [:property UIA_ControlTypePropertyId UIA_ListItemControlTypeId])])

    # '2' = Hyperlinks
    (:define-key km-goto "2" [:ui-hint hint-key-list
      (ui-hint/uia-hinter :condition [:property UIA_ControlTypePropertyId UIA_HyperlinkControlTypeId])])

    # 't' = Tree Items
    (:define-key km-goto "t" [:ui-hint hint-key-list
      (ui-hint/uia-hinter :condition [:property UIA_ControlTypePropertyId UIA_TreeItemControlTypeId])])
    #endregion

    #region [ INSERT ]
    # Split frame logic
    (put km-insert :name "INSERT")
    (:define-key km-insert "h" [:split-frame :horizontal 2 [0.5 0.5] insert-left])
    (:define-key km-insert "l" [:split-frame :horizontal 2 [0.5 0.5] insert-right])
    (:define-key km-insert "k" [:split-frame :vertical 2 [0.5 0.5] insert-above])
    (:define-key km-insert "j" [:split-frame :vertical 2 [0.5 0.5] insert-below])
    #endregion

    #region [ RESIZE ]
    # Value Adjustment via Arrows/Knob
    (put km-resize :name "RESIZE")
    (bind-navigation km-resize) 
    
    (:define-key km-resize "Left"          [:resize-frame -100 0])
    (:define-key km-resize "Right"         [:resize-frame 100 0])
    (:define-key km-resize "Shift + Left"  [:resize-frame 0 -100])
    (:define-key km-resize "Shift + Right" [:resize-frame 0 100])
    (:define-key km-resize ";" [:zoom-in 0.7])
    #endregion

    #region [ SCROLL ]
    # Viewport panning
    (put km-scroll :name "SCROLL")
    (bind-navigation km-scroll)
    
    (:define-key km-scroll "Left"          [:scroll-parent -200])
    (:define-key km-scroll "Right"         [:scroll-parent 200])
    (:define-key km-scroll "Shift + Left"  [:scroll-parent -200])
    (:define-key km-scroll "Shift + Right" [:scroll-parent 200])
    #endregion

    #region [ CARRY ]
    # Window Displacement (Directional)
    (put km-carry :name "CARRY")
    (:define-key km-carry "h" [:move-window :left])
    (:define-key km-carry "j" [:move-window :down])
    (:define-key km-carry "k" [:move-window :up])
    (:define-key km-carry "l" [:move-window :right])
    #endregion

    #region [ ALPHA ]
    # Opacity Control
    (put km-alpha :name "ALPHA")
    (bind-navigation km-alpha)
    
    (:define-key km-alpha "Left"  [:change-window-alpha -25])
    (:define-key km-alpha "Right" [:change-window-alpha 25])
    (:define-key km-alpha "0" [:set-window-alpha 255]) # Reset
    (:define-key km-alpha "5" [:set-window-alpha 128]) # 50%
    (:define-key km-alpha "9" [:set-window-alpha 230]) # 90%
    #endregion

    #region [ OUTER ]
    # Root/Monitor level manipulation
    (put km-outer :name "OUTER")
    (:define-key km-outer "h" [:insert-frame :before activate-inserted-frame :horizontal 1])
    (:define-key km-outer "l" [:insert-frame :after activate-inserted-frame :horizontal 1])
    (:define-key km-outer "k" [:insert-frame :before activate-inserted-frame :vertical 1])
    (:define-key km-outer "j" [:insert-frame :after activate-inserted-frame :vertical 1])
    (:define-key km-outer "f" :reverse-sibling-frames)
    (:define-key km-outer "m" :rotate-sibling-frames)
    #endregion

    #region [ NORMAL ]
    # Default management mode
    (put km-normal :name "NORMAL")
    (bind-navigation km-normal)
    #endregion

    #region [ ROOT (Passthrough) ]
    # System-level hooks when no mode is active
    (put km-root :name "PASSTHROUGH")
    (:define-key km-root "F23" [:set-mode km-normal "NORMAL"])
    (:define-key km-root "Win + Shift + Q" :quit)
    (:define-key km-root "Win + Shift + R" :retile)
    (:define-key km-root "Win + Shift + Esc" [:set-mode km-root "PASSTHROUGH"])
    
    # Apply Root Keymap
    (:set-keymap key-man km-root)
    #endregion

#endregion

#region [ Optional Modules ]
(def auto-close (auto-layout/close-empty-frame jwno/context))
(:enable auto-close)

(def frame-ind (indicator/current-frame-area jwno/context))
(put frame-ind :margin 10)
(:enable frame-ind)

(def scratch (scratch-pad/scratch-pad jwno/context))
(:enable scratch)

(def ui-hint-mod (ui-hint/ui-hint jwno/context))
(:enable ui-hint-mod)
#endregion

#region [ Event Hooks ]

    #region [ Status Updates ]
    # All hooks here trigger JSON status rewrite for the external bar
    (:add-hook hook-man :frame-activated
      (fn [frame] (set current-frame frame) (update-status)))

    (:add-hook hook-man :window-activated
      (fn [win] (set current-window win)
        (when (and win (in win :parent)) (set current-frame (in win :parent)))
        (update-status)))

    (:add-hook hook-man :layout-changed (fn [lo] (update-status)))

    # Filter specific commands to avoid excessive I/O
    (:add-hook hook-man :command-executed
      (fn [cmd args]
        (def update-cmds
          [:adjacent-frame :enum-frame :split-frame
           :insert-frame :close-frame :close-window
           :close-window-or-frame :move-window
           :balance-frames :zoom-in
           :toggle-parent-viewport
           :enum-window-in-frame])
        (when (find |(= $ cmd) update-cmds) (update-status))))
    #endregion

    #region [ Window Rules ]
    # Filter: Ignore "Desktop 2"
    (:add-hook hook-man :filter-window
      (fn [hwnd uia exe desktop] (not= "Desktop 2" (in desktop :name))))

    # Init: Set defaults for new windows
    (:add-hook hook-man :window-created
      (fn [win uia exe desktop]
        (put (in win :tags) :anchor :center)
        (put (in win :tags) :margin 10)
        (set current-window win)
        (when (in win :parent) (set current-frame (in win :parent)))
        
        # Set transparency for terminal/console classes
        (def class (:get_CachedClassName uia))
        (when (or (= class "ConsoleWindowClass") (= class "CASCADIA_HOSTING_WINDOW_CLASS"))
          (:set-alpha win 230))))
    #endregion

    #region [ Monitor ]
    (:add-hook hook-man :monitor-updated
      (fn [frame] (put (in frame :tags) :padding 10)))
    #endregion

#endregion

#region [ Initialization ]
(update-status)
(log/info "Configuration loaded successfully")
#endregion