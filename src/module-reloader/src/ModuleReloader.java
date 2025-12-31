import de.vertico.starface.module.core.ModuleRegistry;
import de.vertico.starface.module.core.model.ModuleProject;
import de.vertico.starface.module.core.model.VariableType;
import de.vertico.starface.module.core.model.Visibility;
import de.vertico.starface.module.core.runtime.IBaseExecutable;
import de.vertico.starface.module.core.runtime.IRuntimeEnvironment;
import de.vertico.starface.module.core.runtime.LoadedModule;
import de.vertico.starface.module.core.runtime.ModuleRuntime;
import de.vertico.starface.module.core.runtime.annotations.Function;
import de.vertico.starface.module.core.runtime.annotations.InputVar;
import de.vertico.starface.module.core.runtime.annotations.OutputVar;
import org.apache.logging.log4j.Logger;

import java.util.Locale;


@Function(
        visibility=Visibility.Private,
        rookieFunction=false,
        description="Updates a module and triggers a reload to memory"
)
public class ModuleReloader implements IBaseExecutable
{
//<editor-fold desc="Private Properties">

    private IRuntimeEnvironment context;


// </editor-fold>

//<editor-fold desc="Starface Properties">

    @InputVar(
            label="ModuleID",
            description="ID of the module, found in the module-descriptor.xml",
            type=VariableType.STRING,
            valueByValueAllowed = false
    )
    public String moduleID = null;

    @InputVar(
            label="ModuleVersion",
            description="Version the module shall be set to",
            type=VariableType.NUMBER,
            valueByValueAllowed = false
    )
    public Integer moduleVersion = -1;

    @OutputVar(
            label="Output",
            description="Outputs some info about the execution",
            type=VariableType.STRING
    )
    public String output = null;

// </editor-fold>

//<editor-fold desc="Getter/Setter">
// </editor-fold>


//<editor-fold desc="Methods">

    @Override
    public void execute(IRuntimeEnvironment context) throws Exception
    {
        Logger log = (Logger) context.getLog();
        log.debug("---- Start module ----");
        output = "";

        if (moduleID == null || moduleID.isEmpty()) {
            log.debug("moduleID: " + moduleID);
            log.error("No moduleID passed. Abort.");
            return;
        }

        log.debug("moduleID: " + moduleID);

        ModuleRegistry MR = context.provider().fetch(ModuleRegistry.class);
        ModuleProject MP = MR.getModule4Edit(MR.getModuleById(moduleID).getId());

        String moduleName = MR.getLocalizedNameByModuleId(moduleID, Locale.GERMAN);
        long modulePrevVersion = MP.getModule().getVersion();

        if (moduleVersion != -1) {
            log.debug("Setting individual module version (" + moduleVersion.toString() + ")");
            ModuleRuntime MRT = context.provider().fetch(ModuleRuntime.class);
            LoadedModule LM = MRT.getModule(moduleID);
            LM.getObject().setVersion(moduleVersion - 2);
            MRT.updateModule(MP);
        }

        log.debug("Module " + moduleName + " (Version " + Long.toString(modulePrevVersion) + ") will be updated and reloaded.");

        MR.updateModule(MP);
        long moduleCurrentVersion = MP.getModule().getVersion();

        String info = "Module " + moduleName + " updated; Version changed from " + Long.toString(modulePrevVersion) + " to version " + Long.toString(moduleCurrentVersion) + ".";
        log.info(info);
        output += info;
    }

// </editor-fold>

}